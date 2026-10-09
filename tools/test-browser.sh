#!/usr/bin/env bash
set -euo pipefail
mix assets.build
SHADCN_PREVIEW=1 mix run --no-halt &
server_pid=$!
trap 'kill "$server_pid" 2>/dev/null || true; wait "$server_pid" 2>/dev/null || true' EXIT
bunx playwright test "$@"
