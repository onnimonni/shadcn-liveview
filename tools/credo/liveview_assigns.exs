defmodule ShadcnLiveview.CredoChecks.LiveViewAssigns do
  @moduledoc """
  Component state must be explicit and assign updates must preserve LiveView change tracking.
  Reject process-dictionary rendering context and direct Map mutations of assigns.
  """
  use Credo.Check, base_priority: :high, category: :warning, exit_status: 1

  @impl true
  def run(%SourceFile{} = source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)
    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
  end

  defp traverse(
         {{:., _, [{:__aliases__, _, [:Process]}, name]}, meta, _args} = ast,
         issues,
         issue_meta
       )
       when name in [:get, :put, :delete] do
    issue =
      format_issue(issue_meta,
        message:
          "Use explicit attrs, slots or LiveView assigns instead of process-dictionary component state.",
        line_no: meta[:line],
        trigger: "Process.#{name}"
      )

    {ast, [issue | issues]}
  end

  defp traverse(
         {{:., _, [{:__aliases__, _, [:Map]}, name]}, meta, [{:assigns, _, _} | _]} = ast,
         issues,
         issue_meta
       )
       when name in [:put, :merge, :update, :update!, :delete] do
    issue =
      format_issue(issue_meta,
        message:
          "Use assign/assign_new/update so LiveView tracks changes; do not mutate assigns with Map.#{name}.",
        line_no: meta[:line],
        trigger: "Map.#{name}"
      )

    {ast, [issue | issues]}
  end

  defp traverse(ast, issues, _issue_meta), do: {ast, issues}
end
