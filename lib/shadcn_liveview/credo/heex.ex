if Code.ensure_loaded?(Credo.Check) do
  defmodule ShadcnLiveview.Credo.Heex do
    @moduledoc false
    # Tolerant HEEx scanner shared by the shadcn_liveview Credo checks. It only needs tags,
    # attributes, nesting and line numbers, so it skips `{...}` expressions, EEx tags,
    # comments and `<script>`/`<style>` bodies instead of parsing them.

    alias Credo.SourceFile

    @void ~w(area base br col embed hr img input link meta param source track wbr)
    @raw ~w(script style)
    @heredoc [~s("""), "'''"]

    @typedoc "`{:string, text}` for quoted values, `{:expr, code}` for `{...}` (root `{@rest}` spreads are named \":root\"), `true` for bare attributes."
    @type value :: {:string, String.t()} | {:expr, String.t()} | true
    @type tag :: %{
            tag: String.t(),
            attrs: [{String.t(), value()}],
            line: pos_integer(),
            children: [tag()]
          }
    @typedoc "Parsed template; `file` is nil for `~H` sigils, else the `.heex` path reported at `report_line`."
    @type template :: %{nodes: [tag()], file: Path.t() | nil, report_line: pos_integer()}

    @doc """
    Every template of an `.ex` file: its `~H` sigils, the colocated `<basename>.html.heex`
    and the `.heex` files matched by literal `embed_templates` calls.
    """
    @spec templates(SourceFile.t()) :: [template()]
    def templates(%SourceFile{filename: filename} = source_file) do
      {sigils, module_line, embeds} =
        Credo.Code.prewalk(source_file, &collect/2, {[], nil, []})

      dir = Path.dirname(filename)
      colocated = Path.rootname(filename, ".ex") <> ".html.heex"

      files =
        [{colocated, module_line || 1} | Enum.reverse(embeds)]
        |> Enum.flat_map(fn
          {{pattern, root}, line} ->
            Path.join(Path.expand(root, dir), pattern)
            |> Path.wildcard()
            |> Enum.filter(&String.ends_with?(&1, ".heex"))
            |> Enum.map(&{&1, line})

          {path, line} ->
            [{path, line}]
        end)
        |> Enum.uniq_by(fn {path, _line} -> Path.expand(path) end)
        |> Enum.flat_map(fn {path, line} ->
          case File.read(path) do
            {:ok, text} -> [%{nodes: parse(text, 1), file: path, report_line: line}]
            {:error, _} -> []
          end
        end)

      Enum.reverse(sigils) ++ files
    end

    defp collect({:sigil_H, meta, [{:<<>>, _, [body]}, _mods]} = ast, {sigils, mod, embeds})
         when is_binary(body) do
      first = if meta[:delimiter] in @heredoc, do: meta[:line] + 1, else: meta[:line]
      template = %{nodes: parse(body, first), file: nil, report_line: first}
      {ast, {[template | sigils], mod, embeds}}
    end

    defp collect({:defmodule, meta, _args} = ast, {sigils, nil, embeds}),
      do: {ast, {sigils, meta[:line], embeds}}

    defp collect({:embed_templates, meta, [pattern | opts]} = ast, {sigils, mod, embeds})
         when is_binary(pattern) do
      root =
        case opts do
          [kw] when is_list(kw) -> literal_root(kw)
          _ -> "."
        end

      {ast, {sigils, mod, [{{pattern, root}, meta[:line]} | embeds]}}
    end

    defp collect(ast, acc), do: {ast, acc}

    defp literal_root(kw) do
      Enum.find_value(kw, ".", fn
        {:root, root} when is_binary(root) -> root
        _ -> nil
      end)
    end

    @doc """
    Report position for `node`: `{line_no, message_prefix, trigger}`. Issues in `.heex` files
    are reported on the module (Credo only knows `.ex` files) with `path:line: ` prefixed.
    """
    @spec location(template(), tag()) :: {pos_integer(), String.t(), term()}
    def location(%{file: nil}, node), do: {node.line, "", "<" <> node.tag}

    def location(%{file: path, report_line: line}, node),
      do: {line, "#{Path.relative_to_cwd(path)}:#{node.line}: ", Credo.Issue.no_trigger()}

    @doc "Every tag in document order with its ancestors, nearest first."
    @spec flatten([tag()], [tag()]) :: [{tag(), [tag()]}]
    def flatten(nodes, ancestors \\ []) do
      Enum.flat_map(nodes, fn node ->
        [{node, ancestors} | flatten(node.children, [node | ancestors])]
      end)
    end

    @doc "Function component name (`<.message>`, `<Message.message>` -> \"message\"); nil for HTML tags."
    @spec component(tag()) :: String.t() | nil
    def component(%{tag: tag}) do
      if String.contains?(tag, "."), do: tag |> String.split(".") |> List.last()
    end

    @doc "True when the template renders any of the named function components."
    @spec uses?([tag()], [String.t()]) :: boolean()
    def uses?(nodes, names),
      do: Enum.any?(flatten(nodes), fn {node, _} -> component(node) in names end)

    @spec attr(tag(), String.t()) :: value() | nil
    def attr(%{attrs: attrs}, name) do
      case List.keyfind(attrs, name, 0) do
        {_, value} -> value
        nil -> nil
      end
    end

    @doc ~S|`{:ok, text}` for `name="x"` and `name={"x"}`; `:missing`; `:dynamic` otherwise.|
    @spec static(tag(), String.t()) :: {:ok, String.t()} | :missing | :dynamic
    def static(node, name) do
      case attr(node, name) do
        nil ->
          :missing

        {:string, text} ->
          {:ok, text}

        {:expr, code} ->
          case Regex.run(~r/\A\s*"([^"\\#]*)"\s*\z/, code) do
            [_, text] -> {:ok, text}
            nil -> :dynamic
          end

        true ->
          {:ok, ""}
      end
    end

    @doc "Parses HEEx source into a tag tree; `line` is the line number of its first line."
    @spec parse(String.t(), pos_integer()) :: [tag()]
    def parse(text, line) do
      [root | _] =
        text
        |> scan(line, [])
        |> Enum.reduce([%{tag: :root, attrs: [], line: line, children: []}], &step/2)
        |> close_all()

      root.children
    end

    defp step({:open, tag, attrs, line, true}, stack),
      do: add_child(stack, node(tag, attrs, line))

    defp step({:open, tag, attrs, line, false}, stack), do: [node(tag, attrs, line) | stack]

    defp step({:close, tag}, stack) do
      if Enum.any?(stack, &(&1.tag == tag)), do: close_until(stack, tag), else: stack
    end

    defp node(tag, attrs, line), do: %{tag: tag, attrs: attrs, line: line, children: []}

    defp close_until([%{tag: tag} = node | rest], tag), do: add_child(rest, finish(node))
    defp close_until([node | rest], tag), do: close_until(add_child(rest, finish(node)), tag)

    defp close_all([root]), do: [finish(root)]
    defp close_all([node | rest]), do: close_all(add_child(rest, finish(node)))

    defp add_child([parent | rest], child),
      do: [%{parent | children: [child | parent.children]} | rest]

    defp finish(node), do: %{node | children: Enum.reverse(node.children)}

    ## Tokens: {:open, tag, attrs, line, self_closing?} and {:close, tag}

    defp scan(<<>>, _line, acc), do: Enum.reverse(acc)

    defp scan("<!--" <> rest, line, acc) do
      {rest, line} = skip_past(rest, "-->", line)
      scan(rest, line, acc)
    end

    defp scan("<%" <> rest, line, acc) do
      {rest, line} = skip_past(rest, "%>", line)
      scan(rest, line, acc)
    end

    defp scan("</" <> rest, line, acc) do
      {tag, rest} = take_name(rest)
      {rest, line} = skip_past(rest, ">", line)
      scan(rest, line, [{:close, tag} | acc])
    end

    defp scan(<<?<, c, _::binary>> = text, line, acc)
         when c in ?a..?z or c in ?A..?Z or c in [?., ?:] do
      {tag, rest} = take_name(binary_part(text, 1, byte_size(text) - 1))
      {attrs, closed?, rest, next} = attrs(rest, line, [])
      open = {:open, tag, attrs, line, closed? or tag in @void}

      if not closed? and tag in @raw do
        {rest, next} = skip_past(rest, "</" <> tag, next)
        {rest, next} = skip_past(rest, ">", next)
        scan(rest, next, [{:close, tag}, open | acc])
      else
        scan(rest, next, [open | acc])
      end
    end

    defp scan("{" <> rest, line, acc) do
      {_code, rest, line} = expr(rest, line)
      scan(rest, line, acc)
    end

    defp scan("\n" <> rest, line, acc), do: scan(rest, line + 1, acc)
    defp scan(<<_, rest::binary>>, line, acc), do: scan(rest, line, acc)

    defp attrs(<<c, rest::binary>>, line, acc) when c in [?\s, ?\t, ?\r],
      do: attrs(rest, line, acc)

    defp attrs("\n" <> rest, line, acc), do: attrs(rest, line + 1, acc)
    defp attrs("/>" <> rest, line, acc), do: {Enum.reverse(acc), true, rest, line}
    defp attrs(">" <> rest, line, acc), do: {Enum.reverse(acc), false, rest, line}
    defp attrs(<<>>, line, acc), do: {Enum.reverse(acc), true, <<>>, line}

    defp attrs("{" <> rest, line, acc) do
      {code, rest, line} = expr(rest, line)
      attrs(rest, line, [{":root", {:expr, code}} | acc])
    end

    defp attrs(text, line, acc) do
      case take_name(text) do
        {"", <<_, rest::binary>>} ->
          attrs(rest, line, acc)

        {name, rest} ->
          {value, rest, line} = value(rest, line)
          attrs(rest, line, [{name, value} | acc])
      end
    end

    defp value(text, line) do
      case skip_space(text, line) do
        {"=" <> rest, next} ->
          case skip_space(rest, next) do
            {"\"" <> rest, next} -> quoted(rest, "\"", next)
            {"'" <> rest, next} -> quoted(rest, "'", next)
            {"{" <> rest, next} -> expr_value(rest, next)
            {rest, next} -> bare_value(rest, next)
          end

        _ ->
          {true, text, line}
      end
    end

    defp quoted(text, quote, line) do
      {inner, rest} =
        case :binary.match(text, quote) do
          {pos, 1} ->
            {binary_part(text, 0, pos), binary_part(text, pos + 1, byte_size(text) - pos - 1)}

          :nomatch ->
            {text, <<>>}
        end

      {{:string, inner}, rest, line + newlines(inner)}
    end

    defp expr_value(text, line) do
      {code, rest, line} = expr(text, line)
      {{:expr, code}, rest, line}
    end

    defp bare_value(text, line) do
      {inner, rest} = take_name(text)
      {{:string, inner}, rest, line}
    end

    defp skip_space(<<c, rest::binary>>, line) when c in [?\s, ?\t, ?\r],
      do: skip_space(rest, line)

    defp skip_space("\n" <> rest, line), do: skip_space(rest, line + 1)
    defp skip_space(text, line), do: {text, line}

    defp take_name(text), do: take_name(text, 0)

    defp take_name(text, n) do
      case text do
        <<_::binary-size(n), c, _::binary>>
        when c not in [?\s, ?\t, ?\n, ?\r, ?>, ?/, ?=, ?{, ?", ?'] ->
          take_name(text, n + 1)

        _ ->
          {binary_part(text, 0, n), binary_part(text, n, byte_size(text) - n)}
      end
    end

    defp skip_past(text, marker, line) do
      case :binary.match(text, marker) do
        {pos, len} ->
          skipped = binary_part(text, 0, pos)
          rest = binary_part(text, pos + len, byte_size(text) - pos - len)
          {rest, line + newlines(skipped)}

        :nomatch ->
          {<<>>, line + newlines(text)}
      end
    end

    defp newlines(text), do: text |> :binary.matches("\n") |> length()

    # `{...}` body with nested braces and Elixir strings (including `#{}` interpolation).
    defp expr(text, line) do
      {n, line, rest} = expr_scan(text, 0, line, 0)
      {binary_part(text, 0, n), rest, line}
    end

    defp expr_scan(<<>>, n, line, _depth), do: {n, line, <<>>}
    defp expr_scan("}" <> rest, n, line, 0), do: {n, line, rest}
    defp expr_scan("}" <> rest, n, line, depth), do: expr_scan(rest, n + 1, line, depth - 1)
    defp expr_scan("{" <> rest, n, line, depth), do: expr_scan(rest, n + 1, line, depth + 1)
    defp expr_scan("\n" <> rest, n, line, depth), do: expr_scan(rest, n + 1, line + 1, depth)

    defp expr_scan(<<q, rest::binary>>, n, line, depth) when q in [?", ?'] do
      {n, line, rest} = string_scan(rest, q, n + 1, line)
      expr_scan(rest, n, line, depth)
    end

    defp expr_scan(<<_, rest::binary>>, n, line, depth), do: expr_scan(rest, n + 1, line, depth)

    defp string_scan(<<>>, _q, n, line), do: {n, line, <<>>}

    defp string_scan(<<?\\, ?\n, rest::binary>>, q, n, line),
      do: string_scan(rest, q, n + 2, line + 1)

    defp string_scan(<<?\\, _, rest::binary>>, q, n, line), do: string_scan(rest, q, n + 2, line)

    defp string_scan("\#{" <> rest, q, n, line) do
      {n, line, rest} = expr_scan(rest, n + 2, line, 0)
      string_scan(rest, q, n + 1, line)
    end

    defp string_scan(<<q, rest::binary>>, q, n, line), do: {n + 1, line, rest}
    defp string_scan("\n" <> rest, q, n, line), do: string_scan(rest, q, n + 1, line + 1)
    defp string_scan(<<_, rest::binary>>, q, n, line), do: string_scan(rest, q, n + 1, line)
  end
end
