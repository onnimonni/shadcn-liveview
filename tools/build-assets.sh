#!/usr/bin/env bash
set -euo pipefail

# Run through `mix assets.package` (portable assets only) or `mix assets.build`
# (portable assets plus the development galleries), after `bun install`.
mode="${1:---preview}"
case "$mode" in
  --package|--preview) ;;
  *) printf 'Usage: bash tools/build-assets.sh [--package|--preview]\n' >&2; exit 1 ;;
esac

mkdir -p priv/static
compiled=$(mktemp assets/css/.tailwind.XXXXXX)
trap 'rm -f "$compiled"' EXIT

build_path="${MIX_BUILD_PATH:-${MIX_BUILD_ROOT:-_build}/${MIX_ENV:-dev}}"
hook_index="$build_path/phoenix-colocated/shadcn_liveview/index.js"
if [[ ! -f "$hook_index" ]]; then
  printf 'Missing colocated hook registry: %s. Run mix assets.package.\n' "$hook_index" >&2
  exit 1
fi

# Bundle the compiler's entire registry, not Phoenix's client or preview entries.
# Embla is resolved here so the distributed ES module has no external imports.
NODE_PATH="$PWD/node_modules${NODE_PATH:+:$NODE_PATH}" \
  bun node_modules/esbuild/bin/esbuild "$hook_index" \
  --bundle --format=esm --target=es2022 --minify \
  --outfile=priv/static/shadcn-hooks.js

# Portable CSS has a system font stack and no network-dependent font/import URLs.
bun node_modules/esbuild/bin/esbuild assets/css/shadcn.css \
  --bundle --conditions=style --outfile="$compiled"
bun node_modules/@tailwindcss/cli/dist/index.mjs \
  -i "$compiled" -o priv/static/shadcn.css --minify
# Tailwind source entry for apps with their own Tailwind v4 build: imports inlined,
# Tailwind at-rules kept, so the consumer compiles one utilities layer.
bun node_modules/esbuild/bin/esbuild assets/css/shadcn.tailwind.css \
  --bundle --conditions=style --legal-comments=none \
  --banner:css='/*! shadcn_liveview Tailwind v4 entry: @import after "tailwindcss". Contains MIT-licensed shadcn/ui (c) 2023 shadcn and tw-animate-css (c) 2025 Wombosvideo; see NOTICE. */' \
  --outfile=priv/static/shadcn.tailwind.css

# shadcn/ui template → LiveView converter for consumers' agents (usage-rules/skills/shadcn-template-to-liveview).
# Self-contained: runs with `node` or `bun` and reads the component API from ../lib at runtime.
bun node_modules/esbuild/bin/esbuild tools/template-to-liveview/cli.ts \
  --bundle --platform=node --format=esm --target=node18 --minify --legal-comments=none \
  --banner:js='#!/usr/bin/env node
// shadcn-to-liveview (shadcn_liveview): converts shadcn/ui React templates to LiveView. Contains MIT-licensed @babel/parser; see NOTICE.' \
  --outfile=priv/shadcn-to-liveview.mjs

if [[ "$mode" == "--package" ]]; then
  exit 0
fi

mkdir -p priv/static/assets/css
# Preview fonts are embedded; public CSS above deliberately does not import them.
bun node_modules/esbuild/bin/esbuild assets/css/app.css \
  --bundle --conditions=style --loader:.woff2=dataurl --loader:.woff=dataurl \
  --outfile="$compiled"
bun node_modules/@tailwindcss/cli/dist/index.mjs \
  -i "$compiled" -o priv/static/assets/css/app.css

bun node_modules/esbuild/bin/esbuild assets/js/react-preview.tsx \
  --tsconfig=assets/js/tsconfig.react.json --bundle --format=esm --target=es2022 \
  --outfile=priv/static/assets/js/react-preview.js

bunx tsx tools/ssr.tsx
