#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
export MIX_BUILD_ROOT="$PWD/_build"
export MIX_ENV=prod
# Runtime: SECRET_KEY_BASE=<64+ byte secret> PHX_HOST=example.com PHX_SERVER=true
#          CONSUMER_PORT=4001 _build/prod/rel/consumer/bin/consumer start
# Production expects HTTPS, normally terminated by a trusted reverse proxy.
mix deps.get --only prod
mix assets.setup
mix compile
mix assets.deploy
mix release --overwrite
