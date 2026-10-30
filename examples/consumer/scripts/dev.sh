#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
export MIX_BUILD_ROOT="$PWD/_build"
# Only Elixir dependencies and esbuild's standalone binary are needed.
# The path dependency provides already-built /shadcn assets; no Node/React/Tailwind install.
mix setup
exec mix phx.server
