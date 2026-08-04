#!/usr/bin/env bash
set -euo pipefail

PREFIX="${PREFIX:?}"
SRC="${SRC_DIR:-$PWD}"
ZIG_TARGET="${ZIG_TARGET:-x86_64-linux-musl}"
DEST="${PREFIX}/musl-static/capnp-janet"
CPU_COUNT="${CPU_COUNT:-$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)}"

command -v zig >/dev/null
command -v meson >/dev/null

WRAP="$(mktemp -d)"
trap 'rm -rf "$WRAP"' EXIT
cat >"${WRAP}/zig-cc" <<EOF
#!/bin/sh
exec zig cc -target ${ZIG_TARGET} "\$@"
EOF
cat >"${WRAP}/zig-c++" <<EOF
#!/bin/sh
exec zig c++ -target ${ZIG_TARGET} "\$@"
EOF
cat >"${WRAP}/zig-ar" <<EOF
#!/bin/sh
exec zig ar "\$@"
EOF
chmod 755 "${WRAP}/zig-cc" "${WRAP}/zig-c++" "${WRAP}/zig-ar"

export CC="${WRAP}/zig-cc" CXX="${WRAP}/zig-c++" AR="${WRAP}/zig-ar"
export PATH="${WRAP}:${PATH}"

BDIR="${SRC}/build-musl"
rm -rf "$BDIR"
meson setup "$BDIR" "$SRC" \
  --prefix="$DEST" \
  --libdir=lib \
  --buildtype=release \
  -Ddefault_library=static \
  --wrap-mode=nofallback
meson compile -C "$BDIR" -j"${CPU_COUNT}"
meson install -C "$BDIR"

# library may land as libcapnp_janet.a
test -f "${DEST}/lib/libcapnp_janet.a" \
  || test -f "${DEST}/lib/libcapnp_janet.so" \
  || find "${DEST}" -name 'libcapnp_janet.a' | grep -q .
test -f "${DEST}/include/capnp-janet/capnp_message.h"
echo "ok: musl-static capnp-janet at ${DEST}"
