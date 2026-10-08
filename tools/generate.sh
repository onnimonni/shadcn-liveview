#!/usr/bin/env bash
set -euo pipefail
bunx tsx tools/generate.tsx
mix format 'lib/shadcn_liveview.ex' 'lib/shadcn_liveview/gallery.ex' 'lib/shadcn_liveview/components/*.ex'
