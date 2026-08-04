#!/usr/bin/env bash
set -euo pipefail
PREFIX="${PREFIX:?}"
SRC="${SRC_DIR:-$PWD}"
CPU_COUNT="${CPU_COUNT:-$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)}"

BDIR="${SRC}/build-host"
rm -rf "$BDIR"
meson setup "$BDIR" "$SRC" \
  --prefix="$PREFIX" \
  --libdir=lib \
  --buildtype=release \
  -Ddefault_library=both \
  --wrap-mode=nofallback
meson compile -C "$BDIR" -j"${CPU_COUNT}"
meson install -C "$BDIR"
test -f "${PREFIX}/include/capnp-janet/capnp_message.h"
echo "ok: capnp-janet host install at ${PREFIX}"
