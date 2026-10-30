#!/usr/bin/env bash
set -euo pipefail
bunx tsx tools/generate.tsx
mix format 'lib/shadcn_liveview.ex' 'lib/shadcn_liveview/gallery.ex' 'lib/shadcn_liveview/components/*.ex'
# Built from the formatted modules so the index mirrors exactly what ships.
bunx tsx tools/generator/component-index.ts
