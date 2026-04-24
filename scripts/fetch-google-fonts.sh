#!/usr/bin/env bash
# Download official hinted Noto TTFs from Google's noto-fonts source tree
# (same family as Google Fonts; static files live here — google/fonts OFL
# zip is mostly variable fonts now, which stb_truetype does not handle).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="${ROOT}/kernel/assets"
mkdir -p "${DEST}"
BASE="https://raw.githubusercontent.com/googlefonts/noto-fonts/main/hinted/ttf"
echo "Fetching Noto Sans + Symbols2 into ${DEST} ..."
curl -fsSL "${BASE}/NotoSans/NotoSans-Regular.ttf" \
  -o "${DEST}/NotoSans-Regular.ttf"
curl -fsSL "${BASE}/NotoSansSymbols2/NotoSansSymbols2-Regular.ttf" \
  -o "${DEST}/NotoSansSymbols2-Regular.ttf"
ls -la "${DEST}/"*.ttf
echo "Done."
