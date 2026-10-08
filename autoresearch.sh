#!/usr/bin/env bash
set -euo pipefail

# 1. Build assets using Phoenix esbuild
mix assets.build >/dev/null 2>&1 || true

# 2. Dump Phoenix LiveView SSR
mix run -e 'File.write!("priv/phoenix_ssr.json", ShadcnLiveview.Gallery.dump_all())' >/dev/null 2>&1

# 3. Run parity comparison suite which emits METRIC lines
npx tsx tools/parity.tsx
