#!/usr/bin/env bash
# Faz 2 — fetch prebuilt Limine binaries into boot/limine and build the
# `limine` host tool used by make-iso.sh.
#
# Re-running updates the working tree to the latest tip of the pinned branch.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="${SIMPLEOS_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"
BOOT="$ROOT/boot"
VERSIONS="$BOOT/versions.env"
TARGET="$BOOT/limine"

[[ -f "$VERSIONS" ]] || { echo "missing $VERSIONS" >&2; exit 1; }
# shellcheck disable=SC1090
source "$VERSIONS"

log()  { printf '\e[1;34m[limine]\e[0m %s\n' "$*"; }
die()  { printf '\e[1;31m[limine]\e[0m %s\n' "$*" >&2; exit 1; }

command -v git  >/dev/null 2>&1 || die "git not installed"
command -v make >/dev/null 2>&1 || die "make not installed"

if [[ -d "$TARGET/.git" ]]; then
    log "updating $TARGET to tip of $LIMINE_VERSION"
    git -C "$TARGET" fetch --depth=1 origin "$LIMINE_VERSION"
    git -C "$TARGET" checkout -q FETCH_HEAD
else
    log "cloning $LIMINE_REPO ($LIMINE_VERSION) into $TARGET"
    rm -rf "$TARGET"
    git clone --depth=1 --branch "$LIMINE_VERSION" "$LIMINE_REPO" "$TARGET"
fi

log "building limine host tool"
make -C "$TARGET"

log "done — $(cd "$TARGET" && git rev-parse --short HEAD) at $TARGET"
