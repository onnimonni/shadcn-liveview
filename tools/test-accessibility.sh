#!/usr/bin/env bash
set -euo pipefail

mix assets.build
mix test test/browser
(
  cd examples/consumer
  export MIX_BUILD_ROOT="$PWD/_build"
  mix assets.build
  mix test test/settings_browser_test.exs
)

# Scan both projects even when one reports violations; preserve failure status.
status=0
MIX_ENV=test mix excessibility "$@" || status=$?
(
  cd examples/consumer
  export MIX_BUILD_ROOT="$PWD/_build"
  MIX_ENV=test mix excessibility "$@"
) || status=$?
exit "$status"
