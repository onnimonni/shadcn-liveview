if Code.ensure_loaded?(Credo.Check) do
  defmodule ShadcnLiveview.Credo.ChatUsesMessageScroller do
    use Credo.Check,
      base_priority: :high,
      category: :warning,
      param_defaults: [
        message_components: ~w(message message_group bubble bubble_group),
        group_components: ~w(message_group bubble_group),
        scroller_components: ~w(message_scroller message_scroller_viewport)
      ],
      explanations: [
        check: """
        A chat thread must follow new messages.

        Looping shadcn_liveview `message`/`bubble` components inside a hand-rolled scroll
        box (`max-height` + `overflow-y: auto`) leaves new messages below the fold: nothing
        scrolls the box when LiveView appends one. The library's `message_scroller` family
        starts at the end, follows new messages while the reader is at the end, and keeps
        the position when older messages are prepended:

            <.message_scroller_provider :let={scroll} auto_scroll default_scroll_position="end">
              <.message_scroller id="chat-scroller" context={scroll} class="h-96">
                <.message_scroller_viewport context={scroll}>
                  <.message_scroller_content>
                    <.message_scroller_item :for={m <- @messages} message_id={m.id}>
                      <.message align={if m.mine, do: "end", else: "start"}>...</.message>
                    </.message_scroller_item>
                  </.message_scroller_content>
                </.message_scroller_viewport>
              </.message_scroller>
            </.message_scroller_provider>

        Flagged: a message component with `:for` (or inside a `:for`/`phx-update="stream"`
        element that sits in a message group or stream container) that forms a thread box:
        the outermost wrapper is a `message_group`/`bubble_group` or stream container, or
        the thread sits in a scroll box (`overflow-auto`/`overflow-y-auto`/`overflow-scroll`
        or `max-h-*` class, or a `scroll_area`). Not flagged when any template of the file
        renders a `message_scroller` or an ancestor has a `phx-hook` (an app-owned scroll
        hook); bare looped messages in page flow (e.g. a comment list) are left alone.
        Templates are `~H` sigils, the colocated `<module file>.html.heex` and literal
        `embed_templates` matches; issues found in a `.heex` file are reported on the module
        with the template's path and line in the message. `.exs` files are skipped.
        """,
        params: [
          message_components: "Function components that render one message or a group of them.",
          group_components:
            "Containers whose looped children count as a thread even when `:for` sits on a plain element.",
          scroller_components:
            "Function components that mean the file already uses the library scroller."
        ]
      ]

    alias ShadcnLiveview.Credo.Heex

    # Tailwind utilities that make a hand-rolled scroll box.
    @scroll_class ~r/(?:^|[\s"':])(?:overflow(?:-y)?-(?:auto|scroll)|max-h-)/

    @impl true
    def run(%SourceFile{filename: filename} = source_file, params) do
      templates =
        if String.ends_with?(filename, ".exs"), do: [], else: Heex.templates(source_file)

      scrollers = Params.get(params, :scroller_components, __MODULE__)

      if Enum.any?(templates, &Heex.uses?(&1.nodes, scrollers)) do
        []
      else
        issue_meta = IssueMeta.for(source_file, params)
        messages = Params.get(params, :message_components, __MODULE__)
        groups = Params.get(params, :group_components, __MODULE__)

        for template <- templates, root <- thread_roots(template, messages, groups) do
          issue_for(issue_meta, template, root)
        end
      end
    end

    # Elements wrapping a looped thread that sits in a thread container or a scroll box.
    defp thread_roots(template, messages, groups) do
      for {node, ancestors} <- Heex.flatten(template.nodes),
          Heex.component(node) in messages,
          looped?(node, ancestors, groups),
          not Enum.any?(ancestors, &Heex.attr(&1, "phx-hook")),
          root = thread_root(node, ancestors, messages),
          container?(root, groups) or Enum.any?([node | ancestors], &scroll_box?/1),
          uniq: true,
          do: root
    end

    # `:for` on the message itself, or on an element inside a group/stream container.
    defp looped?(node, ancestors, groups) do
      Heex.attr(node, ":for") != nil or
        case Enum.find_index(ancestors, &Heex.attr(&1, ":for")) do
          nil -> false
          index -> ancestors |> Enum.drop(index) |> Enum.any?(&container?(&1, groups))
        end
    end

    defp container?(node, groups),
      do: Heex.component(node) in groups or Heex.static(node, "phx-update") == {:ok, "stream"}

    defp scroll_box?(node) do
      String.starts_with?(Heex.component(node) || "", "scroll_area") or
        case Heex.attr(node, "class") do
          {_kind, class} when is_binary(class) -> Regex.match?(@scroll_class, class)
          _ -> false
        end
    end

    # The element to wrap: the outermost message component or stream container around it.
    defp thread_root(node, ancestors, messages) do
      ancestors
      |> Enum.filter(
        &(Heex.component(&1) in messages or Heex.static(&1, "phx-update") == {:ok, "stream"})
      )
      |> List.last(node)
    end

    defp issue_for(issue_meta, template, root) do
      {line_no, prefix, trigger} = Heex.location(template, root)

      scroller_id =
        case Heex.static(root, "id") do
          {:ok, id} when id != "" -> id <> "-scroller"
          _ -> "chat-scroller"
        end

      message =
        prefix <>
          ~s|Chat thread <#{root.tag}> loops messages without the library's message_scroller, | <>
          ~s|so new messages land below the fold and the view never follows them. | <>
          ~s|Fix: wrap the thread and drop any hand-rolled max-height/overflow-y on it: | <>
          ~s|<.message_scroller_provider :let={scroll} auto_scroll default_scroll_position="end">| <>
          ~s|<.message_scroller id="#{scroller_id}" context={scroll} class="h-96">| <>
          ~s|<.message_scroller_viewport context={scroll}><.message_scroller_content>| <>
          ~s|...the existing <#{root.tag}>...| <>
          ~s|</.message_scroller_content></.message_scroller_viewport></.message_scroller>| <>
          ~s|</.message_scroller_provider> (the scroller fills its parent: give it a height via class; | <>
          ~s|optionally wrap each looped message in <.message_scroller_item message_id={m.id}> to keep the position when older messages are prepended).|

      format_issue(issue_meta, message: message, line_no: line_no, trigger: trigger)
    end
  end
end
