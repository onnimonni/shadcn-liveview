defmodule ShadcnLiveview.Credo.ChatChecksTest do
  use Credo.Test.Case

  alias ShadcnLiveview.Credo.ChatUsesMessageScroller
  alias ShadcnLiveview.Credo.ComposerFormClears
  alias ShadcnLiveview.Credo.Heex

  setup_all do
    {:ok, _} = Application.ensure_all_started(:credo)
    :ok
  end

  # The shape Codex shipped in the Clearwell telehealth app (clearwell_live.ex chat/1).
  @clearwell ~S'''
  defmodule TelehealthWeb.ClearwellLive do
    use TelehealthWeb, :live_view

    defp chat(assigns) do
      ~H"""
      <.card class="chat-panel">
        <.card_content>
          <.message_group id="chat-thread" aria-label="Demo message thread" aria-live="polite">
            <.message
              :for={m <- @data}
              id={"msg-" <> m.id}
              align={if m.sender == "Alex Morgan", do: "end", else: "start"}
            >
              <.message_content class="chat-bubble">
                <.message_header>{m.sender}</.message_header><p>{m.text}</p>
              </.message_content>
            </.message>
          </.message_group><.form
            for={@form}
            id="message-form"
            phx-submit="send-message"
            class="form-stack"
            novalidate
          >
            <.input field={@form[:text]} label="Your demo message" placeholder="Type…" /><.button
              type="submit"
            >Send message <.icon name="send" /></.button>
          </.form>
        </.card_content>
      </.card>
      """
    end
  end
  '''

  defp live(template) do
    """
    defmodule MyAppWeb.ChatLive do
      use MyAppWeb, :live_view

      def render(assigns) do
        ~H\"\"\"
    #{template |> String.trim_trailing() |> String.replace(~r/^/m, "    ")}
        \"\"\"
      end
    end
    """
  end

  # Line of the first template line produced by live/1.
  @first 6

  defp check(source, check, params \\ []),
    do: source |> to_source_file() |> run_check(check, params)

  defp tmp_dir(name) do
    dir =
      Path.join(System.tmp_dir!(), "shadcn_credo_#{name}_#{System.unique_integer([:positive])}")

    File.mkdir_p!(dir)
    on_exit(fn -> File.rm_rf!(dir) end)
    dir
  end

  @thread """
  <.message_group id="thread">
    <.message :for={m <- @messages} id={m.id}>{m.text}</.message>
  </.message_group>
  """

  describe "ComposerFormClears" do
    test "flags the Clearwell composer at its form line with the exact fix" do
      @clearwell
      |> check(ComposerFormClears)
      |> assert_issue(fn issue ->
        assert issue.line_no == 18
        assert issue.trigger == "<.form"

        assert issue.message =~
                 ~s|<.form id="message-form" phx-submit="send-message"> never clears|

        assert issue.message =~ "changing only the form's id does not help"
        assert issue.message =~ "give the <.input> on line 25 an id that changes per sent message"

        assert issue.message =~
                 ~s|add id={"message-form-text-\#{@sent_count}"} phx-mounted={@sent_count > 0 && JS.focus()}|

        assert issue.message =~ "sent_count: socket.assigns.sent_count + 1"
      end)
    end

    test "flags controls whose DOM id survives a send, even when the form id changes" do
      for form <- [
            ~s|<.form for={@form} id={"composer"} phx-submit="send"><.input field={@form[:text]} /></.form>|,
            ~s|<.form for={@form} phx-submit="send"><.textarea field={@form[:text]} /></.form>|,
            ~s|<form id="c" phx-submit="send"><input name="text" /><button>Send</button></form>|,
            ~s|<.form for={@form} id="c" phx-submit="send"><.input name="text" id="composer-text" /></.form>|,
            # A per-message form id alone: LiveView still finds the input by `message_text`.
            ~S|<.form for={@form} id={"composer-#{@count}"} phx-submit="send"><.input field={@form[:text]} /></.form>|,
            ~S|<.form for={@form} id={"c-#{@n}"} phx-submit="send"><.form_field :let={a} field={@form[:text]}><.textarea {a} /></.form_field></.form>|
          ] do
        (@thread <> form)
        |> live()
        |> check(ComposerFormClears)
        |> assert_issue(&assert(&1.line_no == @first + 3))
      end
    end

    test "counts hidden inputs and buttons out, module-qualified components in" do
      """
      <ShadcnLiveview.Components.Bubble.bubble :for={m <- @messages}>{m.text}</ShadcnLiveview.Components.Bubble.bubble>
      <.form for={@form} id="composer" phx-submit="send">
        <input type="hidden" name="room" value={@room} />
        <.input type="hidden" field={@form[:room]} />
        <ShadcnLiveview.Components.InputGroup.input_group_textarea name="text" />
        <.button type="submit">Send</.button>
      </.form>
      """
      |> live()
      |> check(ComposerFormClears)
      |> assert_issue(&assert(&1.line_no == @first + 1))
    end

    test "accepts controls replaced per message and forms that reset themselves" do
      for form <- [
            ~S|<.form for={@form} id="c" phx-submit="send"><.input field={@form[:text]} id={"c-text-#{@count}"} /></.form>|,
            ~S|<.form for={@form} id={@form.id} phx-submit="send"><.input field={@form[:text]} /></.form>|,
            ~S|<form id={"c-#{@n}"} phx-submit="send"><input name="text" /></form>|,
            ~S|<.form for={@form} id="c" phx-submit="send" phx-change="typing"><.input field={@form[:text]} /></.form>|,
            ~S|<.form for={@form} id="c" phx-submit="send" phx-hook="ResetOnSubmit"><.input field={@form[:text]} /></.form>|,
            ~S'<.form for={@form} id="c" phx-submit={JS.push("send") |> JS.dispatch("reset")}><.input field={@form[:text]} /></.form>'
          ] do
        (@thread <> form) |> live() |> check(ComposerFormClears) |> refute_issues()
      end
    end

    test "ignores non-chat forms and forms with several fields" do
      ~s|<.form for={@q} id="search" phx-submit="search"><.input field={@q[:term]} type="search" /></.form>|
      |> live()
      |> check(ComposerFormClears)
      |> refute_issues()

      (@thread <>
         """
         <.form for={@profile} id="settings" phx-submit="save">
           <.input field={@profile[:name]} /><.input field={@profile[:email]} type="email" />
         </.form>
         """)
      |> live()
      |> check(ComposerFormClears)
      |> refute_issues()
    end

    test "checks the colocated .html.heex and reports its path and line" do
      dir = tmp_dir("colocated")
      ex = Path.join(dir, "chat_live.ex")

      File.write!(Path.join(dir, "chat_live.html.heex"), """
      <h1>Chat</h1>
      #{@thread}<.form for={@form} id="composer" phx-submit="send">
        <.input field={@form[:text]} />
      </.form>
      """)

      "defmodule MyAppWeb.ChatLive do\n  use MyAppWeb, :live_view\nend\n"
      |> to_source_file(ex)
      |> run_check(ComposerFormClears)
      |> assert_issue(fn issue ->
        assert issue.filename == ex
        assert issue.line_no == 1
        assert issue.message =~ ~r/chat_live\.html\.heex:5: Chat composer/
      end)
    end

    test "checks templates matched by embed_templates" do
      dir = tmp_dir("embedded")
      File.mkdir_p!(Path.join(dir, "chat_html"))
      ex = Path.join(dir, "chat_html.ex")

      File.write!(Path.join(dir, "chat_html/show.html.heex"), """
      #{@thread}<.form for={@form} id="composer" phx-submit="send"><.input field={@form[:text]} /></.form>
      """)

      "defmodule MyAppWeb.ChatHTML do\n  use MyAppWeb, :html\n\n  embed_templates \"chat_html/*\"\nend\n"
      |> to_source_file(ex)
      |> run_check(ComposerFormClears)
      |> assert_issue(fn issue ->
        assert issue.line_no == 4
        assert issue.message =~ ~r/chat_html\/show\.html\.heex:4: /
      end)
    end

    test "skips .exs files" do
      @clearwell
      |> to_source_file("test/chat_test.exs")
      |> run_check(ComposerFormClears)
      |> refute_issues()
    end
  end

  describe "ChatUsesMessageScroller" do
    test "flags the Clearwell thread at its message_group line with the exact fix" do
      @clearwell
      |> check(ChatUsesMessageScroller)
      |> assert_issue(fn issue ->
        assert issue.line_no == 8
        assert issue.trigger == "<.message_group"

        assert issue.message =~
                 "<.message_group> loops messages without the library's message_scroller"

        assert issue.message =~
                 ~s|<.message_scroller_provider :let={scroll} auto_scroll default_scroll_position="end">|

        assert issue.message =~ ~s|<.message_scroller id="chat-thread-scroller" context={scroll}|

        assert issue.message =~
                 "<.message_scroller_viewport context={scroll}><.message_scroller_content>"
      end)
    end

    test "flags looped groups, loops inside groups and stream containers" do
      for {thread, line} <- [
            {~s|<.message_group :for={g <- @groups}><.message>{g.text}</.message></.message_group>|,
             0},
            {"<.bubble_group>\n  <div :for={m <- @messages}><.bubble>{m.text}</.bubble></div>\n</.bubble_group>",
             0},
            {"<div id=\"msgs\" phx-update=\"stream\">\n  <div :for={{id, m} <- @streams.messages} id={id}>\n    <.bubble>{m.text}</.bubble>\n  </div>\n</div>",
             0}
          ] do
        thread
        |> live()
        |> check(ChatUsesMessageScroller)
        |> assert_issue(&assert(&1.line_no == @first + line))
      end
    end

    test "accepts threads inside message_scroller, even from another function in the file" do
      """
      <.message_scroller_provider :let={scroll} auto_scroll>
        <.message_scroller id="chat" context={scroll} class="h-96">
          <.message_scroller_viewport context={scroll}>
            <.message_scroller_content>#{@thread}</.message_scroller_content>
          </.message_scroller_viewport>
        </.message_scroller>
      </.message_scroller_provider>
      """
      |> live()
      |> check(ChatUsesMessageScroller)
      |> refute_issues()

      ~S'''
      defmodule MyAppWeb.ChatLive do
        use MyAppWeb, :live_view

        def render(assigns) do
          ~H"""
          <.message_scroller_provider :let={scroll} auto_scroll>
            <.message_scroller id="chat" context={scroll}><.thread messages={@messages} /></.message_scroller>
          </.message_scroller_provider>
          """
        end

        defp thread(assigns), do: ~H"<.message :for={m <- @messages}>{m.text}</.message>"
      end
      '''
      |> check(ChatUsesMessageScroller)
      |> refute_issues()
    end

    test "ignores single messages, per-item bubbles, page-flow comment lists and app scroll hooks" do
      for template <- [
            ~s|<.message_group><.message>Welcome!</.message></.message_group>|,
            ~s|<.card :for={post <- @posts}><.bubble>{post.excerpt}</.bubble></.card>|,
            # r2-codex agent site: task comments in page flow, composer right below them.
            ~s|<.card_content><.message :for={c <- @comments} id={c.id}>{c.body}</.message></.card_content>|,
            ~s|<div id="t" phx-hook="ScrollBottom"><.message :for={m <- @messages}>{m.text}</.message></div>|
          ] do
        template |> live() |> check(ChatUsesMessageScroller) |> refute_issues()
      end
    end

    test "flags bare looped messages inside a hand-rolled scroll box" do
      for box <- [
            ~s|<div class="max-h-96 overflow-y-auto">|,
            ~s|<div class={["flex flex-col", "overflow-auto"]}>|,
            ~s|<.scroll_area class="h-72">|
          ] do
        tag = box |> String.split([" ", ">"], parts: 2) |> hd() |> String.trim_leading("<")

        (box <> "\n  <.bubble :for={m <- @messages}>{m.text}</.bubble>\n</#{tag}>")
        |> live()
        |> check(ChatUsesMessageScroller)
        |> assert_issue(&assert(&1.line_no == @first + 1 and &1.trigger == "<.bubble"))
      end
    end

    test "respects custom component lists" do
      @thread
      |> live()
      |> check(ChatUsesMessageScroller, scroller_components: ["message_group"])
      |> refute_issues()
    end

    test "reports colocated .html.heex threads with their path and line" do
      dir = tmp_dir("thread")
      ex = Path.join(dir, "chat_live.ex")
      File.write!(Path.join(dir, "chat_live.html.heex"), "<h1>Chat</h1>\n" <> @thread)

      "defmodule MyAppWeb.ChatLive do\n  use MyAppWeb, :live_view\nend\n"
      |> to_source_file(ex)
      |> run_check(ChatUsesMessageScroller)
      |> assert_issue(
        &assert(&1.message =~ ~r/chat_live\.html\.heex:2: Chat thread <\.message_group>/)
      )
    end
  end

  test "the scanner keeps line numbers across expressions, comments and scripts" do
    nodes =
      Heex.parse(
        """
        <!-- <.message :for={x <- y}> -->
        <div class={["a",
          "b \#{if @x, do: "}"}"]}>{"<.fake>"}</div>
        <script>if (a<b) { x("</div>") }</script>
        <%= if @x do %><.input
          type="text"
        /><% end %>
        """,
        10
      )

    assert [{"div", 11}, {"script", 13}, {".input", 14}] =
             nodes
             |> Heex.flatten()
             |> Enum.map(fn {n, _} -> {n.tag, n.line} end)
  end
end
