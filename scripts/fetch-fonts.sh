#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
D="$ROOT/kernel/assets"
mkdir -p "$D"
curl -fsSL -o "$D/Roboto-Regular.ttf" \
  "https://raw.githubusercontent.com/googlefonts/roboto/main/src/hinted/Roboto-Regular.ttf"
curl -fsSL -o "$D/NotoSansSymbols2-Regular.ttf" \
  "https://raw.githubusercontent.com/googlefonts/noto-fonts/main/hinted/ttf/NotoSansSymbols2/NotoSansSymbols2-Regular.ttf"
echo "Fonts installed under $D"
