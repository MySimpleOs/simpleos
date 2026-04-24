#!/usr/bin/env bash
# Generate Limine config: resolution from display.conf (width x height).
# Usage: gen-limine-conf.sh <display.conf> <limine.conf.in> <out.conf>
set -euo pipefail

die() { printf '%s\n' "$*" >&2; exit 1; }

[[ $# -eq 3 ]] || die "usage: $0 <display.conf> <limine.conf.in> <out.conf>"

DISP="$1"
TEMPLATE="$2"
OUT="$3"

[[ -f "$DISP" ]]     || die "missing $DISP"
[[ -f "$TEMPLATE" ]] || die "missing $TEMPLATE"

width= height=
while IFS= read -r line || [[ -n "$line" ]]; do
  [[ "$line" =~ ^[[:space:]]*# ]] && continue
  line="${line%%#*}"
  line="${line//$'\r'/}"
  if [[ "$line" =~ ^[[:space:]]*width[[:space:]]*=[[:space:]]*([0-9]+)[[:space:]]*$ ]]; then
    width="${BASH_REMATCH[1]}"
  elif [[ "$line" =~ ^[[:space:]]*height[[:space:]]*=[[:space:]]*([0-9]+)[[:space:]]*$ ]]; then
    height="${BASH_REMATCH[1]}"
  fi
done < "$DISP"

res_line=
if [[ -n "$width" && -n "$height" ]]; then
  if (( width >= 320 && width <= 16384 && height >= 240 && height <= 16384 )); then
    res_line="    resolution: ${width}x${height}"
  else
    printf 'gen-limine-conf: width/height out of range (%sx%s) — omitting resolution\n' \
      "$width" "$height" >&2
  fi
else
  printf 'gen-limine-conf: width/height not both set in %s — omitting resolution (Limine auto)\n' \
    "$DISP" >&2
fi

mkdir -p "$(dirname "$OUT")"
: >"$OUT.tmp"
while IFS= read -r line || [[ -n "$line" ]]; do
  if [[ "$line" == "__LIMINE_RESOLUTION__" ]]; then
    if [[ -n "$res_line" ]]; then printf '%s\n' "$res_line" >>"$OUT.tmp"; fi
  else
    printf '%s\n' "$line" >>"$OUT.tmp"
  fi
done < "$TEMPLATE"
mv "$OUT.tmp" "$OUT"
