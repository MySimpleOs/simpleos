#!/usr/bin/env bash
# Download hinted TTFs from official Google font repos (static files for
# stb_truetype — variable fonts are not supported).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="${ROOT}/kernel/assets"
mkdir -p "${DEST}"
echo "Fetching Roboto + Noto Sans Symbols2 into ${DEST} ..."
curl -fsSL "https://raw.githubusercontent.com/googlefonts/roboto/main/src/hinted/Roboto-Regular.ttf" \
  -o "${DEST}/Roboto-Regular.ttf"
curl -fsSL "https://raw.githubusercontent.com/googlefonts/noto-fonts/main/hinted/ttf/NotoSansSymbols2/NotoSansSymbols2-Regular.ttf" \
  -o "${DEST}/NotoSansSymbols2-Regular.ttf"
ls -la "${DEST}/"*.ttf
echo "Done."
