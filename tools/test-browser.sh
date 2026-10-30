#!/usr/bin/env bash
set -euo pipefail
mix assets.build
mix test test/browser "$@"
(
  cd examples/consumer
  export MIX_BUILD_ROOT="$PWD/_build"
  mix assets.build
  mix test test/settings_browser_test.exs
)
SHADCN_PREVIEW=1 mix run --no-halt &
server_pid=$!
trap 'kill "$server_pid" 2>/dev/null || true; wait "$server_pid" 2>/dev/null || true' EXIT
# Playwright's first page.goto fails with ERR_CONNECTION_REFUSED if the server is still booting.
for _ in $(seq 1 120); do
  curl -fsS -o /dev/null http://127.0.0.1:4000/preview/liveview.html 2>/dev/null && break
  kill -0 "$server_pid" 2>/dev/null || { echo "preview server exited" >&2; exit 1; }
  sleep 0.5
done
bunx playwright test
