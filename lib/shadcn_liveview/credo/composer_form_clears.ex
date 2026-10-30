if Code.ensure_loaded?(Credo.Check) do
  defmodule ShadcnLiveview.Credo.ComposerFormClears do
    use Credo.Check,
      base_priority: :high,
      category: :warning,
      param_defaults: [
        message_components:
          ~w(message message_group bubble bubble_group message_scroller message_scroller_provider message_scroller_viewport message_scroller_content message_scroller_item),
        text_inputs: ~w(input textarea input_group_input input_group_textarea)
      ],
      explanations: [
        check: """
        A chat composer must clear after a message is sent.

        A submit handler usually re-assigns a blank form, e.g.
        `assign(socket, form: to_form(%{"text" => ""}, as: :message))`. The input's
        server-rendered value is `""` before and after the send, so LiveView sends no
        diff for it and the browser keeps the typed text; pressing Enter again posts a
        duplicate. Changing only the form's id does not help: LiveView matches the input
        by its own id (`@form[:text]` gives `message_text`) and keeps the existing element.

        Give the text control an id that changes per sent message, so LiveView replaces
        it with an empty one, and focus the new control:

            <.form for={@form} id="composer" phx-submit="send">
              <.input
                field={@form[:text]}
                id={"composer-text-\#{@sent_count}"}
                phx-mounted={@sent_count > 0 && JS.focus()}
              />
            </.form>

            def handle_event("send", %{"message" => %{"text" => text}}, socket) do
              # ...store the message...
              {:noreply,
               assign(socket,
                 sent_count: socket.assigns.sent_count + 1,
                 form: to_form(%{"text" => ""}, as: :message)
               )}
            end

        (`sent_count: 0` in mount; `JS` is `Phoenix.LiveView.JS`.)

        Flagged: a form with `phx-submit`, no `phx-change`, no `phx-hook` and no `JS`
        submit command, containing exactly one free-text control whose DOM id stays the
        same across sends (a static `id`, an id derived from `field`/`{...}` attributes, or
        no id inside a form whose own id is static), in a template that also renders a
        shadcn_liveview message component (`message`, `message_group`, `bubble`,
        `message_scroller`...). Templates are `~H` sigils, the colocated
        `<module file>.html.heex` and literal `embed_templates` matches; issues found in a
        `.heex` file are reported on the module with the template's path and line in the
        message. `.exs` files are skipped.
        """,
        params: [
          message_components:
            "Function component names that mark a template as a chat (matched on the last segment, so `<.message>` and `<Message.message>` both count).",
          text_inputs:
            "Function components counted as free-text controls (besides HTML `<input>` and `<textarea>`); a static non-text `type` (hidden, checkbox, select...) excludes them."
        ]
      ]

    alias ShadcnLiveview.Credo.Heex

    @text_types ~w(text search email url tel password textarea)

    @impl true
    def run(%SourceFile{filename: filename} = source_file, params) do
      if String.ends_with?(filename, ".exs") do
        []
      else
        issue_meta = IssueMeta.for(source_file, params)
        chat = Params.get(params, :message_components, __MODULE__)
        inputs = Params.get(params, :text_inputs, __MODULE__)

        for template <- Heex.templates(source_file),
            Heex.uses?(template.nodes, chat),
            {form, _ancestors} <- Heex.flatten(template.nodes),
            control = stuck_control(form, inputs) do
          issue_for(issue_meta, template, form, control)
        end
      end
    end

    # The composer's only text control when it survives a send with its typed value.
    defp stuck_control(node, inputs) do
      with true <- form?(node) and Heex.attr(node, "phx-submit") != nil,
           true <- Heex.attr(node, "phx-change") == nil and Heex.attr(node, "phx-hook") == nil,
           false <- js_submit?(node),
           [control] <-
             for(
               {child, _} <- Heex.flatten(node.children),
               text_control?(child, inputs),
               do: child
             ),
           true <- stable_id?(node, control) do
        control
      else
        _ -> nil
      end
    end

    defp form?(node), do: node.tag == "form" or Heex.component(node) == "form"

    # `phx-submit={JS.push(...) |> JS.dispatch(...)}` may reset the form client-side.
    defp js_submit?(node) do
      case Heex.attr(node, "phx-submit") do
        {:expr, code} -> String.contains?(code, "JS.")
        _ -> false
      end
    end

    defp text_control?(node, inputs) do
      case Heex.component(node) do
        nil -> node.tag == "textarea" or (node.tag == "input" and text_type?(node))
        name -> name in inputs and text_type?(node)
      end
    end

    defp text_type?(node) do
      case Heex.static(node, "type") do
        {:ok, type} -> type in @text_types
        _missing_or_dynamic -> true
      end
    end

    # LiveView keeps (and does not clear) an element whose id it finds again.
    defp stable_id?(form, control) do
      case Heex.static(control, "id") do
        {:ok, _id} ->
          true

        :dynamic ->
          false

        :missing ->
          if Heex.attr(control, "field") || Heex.attr(control, ":root") do
            # Derived from the form's id, e.g. `message_text`.
            not form_id_varies?(form)
          else
            # An unkeyed control is rebuilt only when its form is replaced.
            Heex.static(form, "id") != :dynamic
          end
      end
    end

    # `id={@form.id}`: to_form(..., id: ...) may vary the derived control ids per message.
    defp form_id_varies?(form) do
      case Heex.attr(form, "id") do
        {:expr, code} -> Regex.match?(~r/\.id\b/, code)
        _ -> false
      end
    end

    defp issue_for(issue_meta, template, form, control) do
      {line_no, prefix, trigger} = Heex.location(template, form)
      id = static_or(form, "id", "composer")
      event = static_or(form, "phx-submit", "send")

      message =
        prefix <>
          ~s|Chat composer <#{form.tag} id="#{id}" phx-submit="#{event}"> never clears after sending: | <>
          ~s|its <#{control.tag}> keeps the same DOM id, and re-assigning a blank form (e.g. to_form(%{"text" => ""}, as: :message)) | <>
          ~s|renders the same value "" as before, so LiveView keeps the element with the typed text (Enter again posts a duplicate); | <>
          ~s|changing only the form's id does not help. | <>
          ~s|Fix: give the <#{control.tag}> on line #{control.line} an id that changes per sent message and focus the new one: | <>
          ~s|add id={"#{id}-text-\#{@sent_count}"} phx-mounted={@sent_count > 0 && JS.focus()} to it, | <>
          ~s|assign sent_count: 0 in mount, and in the "#{event}" handler | <>
          ~s|assign(socket, sent_count: socket.assigns.sent_count + 1, form: to_form(%{"text" => ""}, as: :message)).|

      format_issue(issue_meta, message: message, line_no: line_no, trigger: trigger)
    end

    defp static_or(node, name, default) do
      case Heex.static(node, name) do
        {:ok, value} when value != "" -> value
        _ -> default
      end
    end
  end
end
