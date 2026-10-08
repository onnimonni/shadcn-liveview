{ pkgs, config, ... }:
{
  # Bun runs the React reference renderer, converter and npm-installed asset tools.
  # tsx's compatibility runtime is declared too; project commands use Bun/Bunx.
  # Git/GitHub CLI support upstream updates and repository maintenance.
  # Bash runs the generation and CSS build scripts on every platform.
  packages = [
    pkgs.bun
    pkgs.nodejs
    pkgs.git
    pkgs.gh
    pkgs.bashInteractive
    pkgs.beamPackages.rebar3
  ];

  # Use one BEAM package set for Elixir/Mix and the matching Erlang/OTP runtime.
  languages.elixir.enable = true;
  languages.erlang = {
    enable = true;
    lsp.enable = false;
  };
  env.MIX_REBAR3 = "${pkgs.beamPackages.rebar3}/bin/rebar3";
  # Do not reuse BEAM artifacts compiled by a different host OTP/Elixir version.
  env.MIX_BUILD_ROOT = "${config.devenv.state}/mix-build";

  # Project dependencies supply Phoenix, Credo, esbuild and Tailwind.
  # Keep installation explicit rather than fetching dependencies on shell entry.
  scripts.setup-project.exec = ''
    set -euo pipefail
    mix local.hex --force
    mix deps.get
    bun install --frozen-lockfile
  '';

  scripts.generate-components.exec = ''
    bash tools/generate.sh
  '';
  scripts.check-components.exec = ''
    mix quality
  '';

  scripts.test-components.exec = ''
    bun run test
  '';
  scripts.update-shadcn.exec = ''
    bun run vendor
  '';
  scripts.preview-components.exec = ''
    set -euo pipefail
    mix assets.build
    SHADCN_PREVIEW=1 mix run --no-halt
  '';
}
