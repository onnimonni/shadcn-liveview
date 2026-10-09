#!/usr/bin/env bash
set -euo pipefail

mkdir -p priv/static/assets/css
compiled=$(mktemp assets/css/.tailwind.XXXXXX)
trap 'rm -f "$compiled"' EXIT

# Resolve imported font URLs before Tailwind; retain the input directory for @source.
bun node_modules/esbuild/bin/esbuild assets/css/app.css \
  --bundle --conditions=style --loader:.woff2=dataurl --loader:.woff=dataurl \
  --outfile="$compiled"
bun node_modules/@tailwindcss/cli/dist/index.mjs \
  -i "$compiled" -o priv/static/assets/css/app.css

bun node_modules/esbuild/bin/esbuild assets/js/react-preview.tsx \
  --tsconfig=assets/js/tsconfig.react.json --bundle --format=esm --target=es2022 \
  --outfile=priv/static/assets/js/react-preview.js

bunx tsx tools/ssr.tsx
