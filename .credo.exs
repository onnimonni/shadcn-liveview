%{
  configs: [
    %{
      name: "default",
      # test/fixtures holds unmodified `mix phx.new` output for the installer tests.
      files: %{
        included: ["lib/", "test/", "config/", "mix.exs", "tools/credo/"],
        excluded: ["test/fixtures/"]
      },
      strict: true,
      requires: ["tools/credo/liveview_assigns.exs"],
      checks: %{extra: [{ShadcnLiveview.CredoChecks.LiveViewAssigns, []}]}
    }
  ]
}
