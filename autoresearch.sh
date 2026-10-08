#!/usr/bin/env bash
set -euo pipefail

# 1. Compile Tailwind utilities and bundle assets; failures invalidate the run.
mix assets.build

# 2. Dump Phoenix LiveView SSR
mix run -e 'File.write!("priv/phoenix_ssr.json", ShadcnLiveview.Gallery.dump_all())' >/dev/null 2>&1

# 3. Run parity comparison suite which emits METRIC lines
bunx tsx tools/parity.tsx
