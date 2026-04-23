#!/usr/bin/env bash
# Faz 1 — build binutils + gcc cross-compiler for SimpleOS.
# Installs into $SIMPLEOS_ROOT/toolchain/out.
#
# Re-entrant: finished stages are skipped via marker files. For a clean
# rebuild run `make distclean` at the repo root first.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="${SIMPLEOS_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"
TC="$ROOT/toolchain"
VERSIONS="$TC/versions.env"

[[ -f "$VERSIONS" ]] || { echo "missing $VERSIONS" >&2; exit 1; }
# shellcheck disable=SC1090
source "$VERSIONS"

PREFIX="$TC/out"
CACHE="$TC/cache"
BUILD="$TC/build"
JOBS="${JOBS:-$(nproc 2>/dev/null || echo 2)}"

BINUTILS_TARBALL="binutils-${BINUTILS_VERSION}.tar.xz"
BINUTILS_URL="${GNU_MIRROR}/binutils/${BINUTILS_TARBALL}"
GCC_TARBALL="gcc-${GCC_VERSION}.tar.xz"
GCC_URL="${GNU_MIRROR}/gcc/gcc-${GCC_VERSION}/${GCC_TARBALL}"

log()  { printf '\e[1;34m[toolchain]\e[0m %s\n' "$*"; }
warn() { printf '\e[1;33m[toolchain]\e[0m %s\n' "$*" >&2; }
die()  { printf '\e[1;31m[toolchain]\e[0m %s\n' "$*" >&2; exit 1; }

check_host() {
    local missing=()
    for bin in gcc g++ make tar xz bison flex makeinfo gettext sha256sum; do
        command -v "$bin" >/dev/null 2>&1 || missing+=("$bin")
    done
    if command -v curl >/dev/null 2>&1 || command -v wget >/dev/null 2>&1; then :; else
        missing+=("curl|wget")
    fi
    if ((${#missing[@]})); then
        die "missing host tools: ${missing[*]} — see toolchain/README.md for the package list"
    fi
}

fetch() {
    local url="$1" out="$2" sha="$3"
    mkdir -p "$(dirname "$out")"
    if [[ -f "$out" ]]; then
        log "cached $(basename "$out")"
    else
        log "downloading $(basename "$out")"
        if command -v curl >/dev/null 2>&1; then
            curl -L --fail -o "$out.part" "$url"
        else
            wget -O "$out.part" "$url"
        fi
        mv "$out.part" "$out"
    fi
    if [[ -n "$sha" ]]; then
        log "verifying sha256 of $(basename "$out")"
        echo "$sha  $out" | sha256sum --check --status \
            || die "sha256 mismatch for $(basename "$out")"
    else
        warn "$(basename "$out"): no SHA-256 pin (observed: $(sha256sum "$out" | awk '{print $1}'))"
    fi
}

extract() {
    local tarball="$1" dest_parent="$2" src_dir="$3"
    if [[ -f "$src_dir/.extracted" ]]; then
        log "already extracted $(basename "$src_dir")"
        return
    fi
    mkdir -p "$dest_parent"
    log "extracting $(basename "$tarball")"
    tar -xf "$tarball" -C "$dest_parent"
    : > "$src_dir/.extracted"
}

build_binutils() {
    local src="$BUILD/binutils-${BINUTILS_VERSION}"
    local obj="$BUILD/build-binutils"
    if [[ -f "$obj/.installed" ]]; then
        log "binutils already installed"
        return
    fi
    mkdir -p "$obj"
    log "configuring binutils for $TARGET"
    ( cd "$obj"
      "$src/configure" \
          --target="$TARGET" \
          --prefix="$PREFIX" \
          --with-sysroot \
          --disable-nls \
          --disable-werror
      log "building binutils (jobs=$JOBS)"
      make -j"$JOBS"
      log "installing binutils"
      make install )
    : > "$obj/.installed"
}

build_gcc() {
    local src="$BUILD/gcc-${GCC_VERSION}"
    local obj="$BUILD/build-gcc"
    if [[ -f "$obj/.installed" ]]; then
        log "gcc already installed"
        return
    fi
    if [[ ! -f "$src/.prereqs" ]]; then
        log "downloading gcc prerequisites (gmp/mpfr/mpc/isl)"
        ( cd "$src" && ./contrib/download_prerequisites )
        : > "$src/.prereqs"
    fi
    mkdir -p "$obj"
    log "configuring gcc for $TARGET"
    ( cd "$obj"
      "$src/configure" \
          --target="$TARGET" \
          --prefix="$PREFIX" \
          --disable-nls \
          --enable-languages=c,c++ \
          --without-headers
      log "building gcc (jobs=$JOBS) — this is the long part"
      make -j"$JOBS" all-gcc
      make -j"$JOBS" all-target-libgcc
      log "installing gcc"
      make install-gcc
      make install-target-libgcc )
    : > "$obj/.installed"
}

main() {
    log "SimpleOS cross-toolchain build"
    log "  target   = $TARGET"
    log "  binutils = $BINUTILS_VERSION"
    log "  gcc      = $GCC_VERSION"
    log "  prefix   = $PREFIX"
    log "  jobs     = $JOBS"

    check_host
    mkdir -p "$CACHE" "$BUILD" "$PREFIX"

    fetch "$BINUTILS_URL" "$CACHE/$BINUTILS_TARBALL" "${BINUTILS_SHA256:-}"
    fetch "$GCC_URL"      "$CACHE/$GCC_TARBALL"      "${GCC_SHA256:-}"

    extract "$CACHE/$BINUTILS_TARBALL" "$BUILD" "$BUILD/binutils-${BINUTILS_VERSION}"
    extract "$CACHE/$GCC_TARBALL"      "$BUILD" "$BUILD/gcc-${GCC_VERSION}"

    build_binutils
    build_gcc

    log "done — run 'source scripts/env.sh && $TARGET-gcc --version' to verify"
}

main "$@"
