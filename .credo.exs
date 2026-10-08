%{
  configs: [
    %{
      name: "default",
      files: %{included: ["lib/", "test/", "config/", "mix.exs", "tools/credo/"]},
      strict: true,
      requires: ["tools/credo/liveview_assigns.exs"],
      checks: %{extra: [{ShadcnLiveview.CredoChecks.LiveViewAssigns, []}]}
    }
  ]
}
