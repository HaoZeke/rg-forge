#!/usr/bin/env bash
# Build libcapnp_c.a for x86_64-linux-musl via zig; install under $PREFIX/musl-static/.
set -euo pipefail

PREFIX="${PREFIX:?}"
SRC="${SRC_DIR:-$PWD}"
ZIG_TARGET="${ZIG_TARGET:-x86_64-linux-musl}"
DEST="${PREFIX}/musl-static/c-capnproto"
CPU_COUNT="${CPU_COUNT:-$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)}"

command -v zig >/dev/null
command -v meson >/dev/null
command -v ninja >/dev/null

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

export CC="${WRAP}/zig-cc"
export CXX="${WRAP}/zig-c++"
export AR="${WRAP}/zig-ar"
export PATH="${WRAP}:${PATH}"

BDIR="${SRC}/build-musl"
rm -rf "$BDIR"
meson setup "$BDIR" "$SRC" \
  --prefix="$DEST" \
  --libdir=lib \
  --buildtype=release \
  -Ddefault_library=static \
  -Denable_tests=false \
  --wrap-mode=nofallback

meson compile -C "$BDIR" -j"${CPU_COUNT}"
meson install -C "$BDIR"

test -f "${DEST}/lib/libcapnp_c.a"
test -f "${DEST}/include/capnp_c.h" || test -f "${DEST}/include/capnp/c/capn.h" || {
  # header layout may vary; accept any capnp_c.h under include
  find "${DEST}/include" -name 'capnp_c.h' | grep -q .
}

# Normalize pkg-config prefix for consumers that point PKG_CONFIG_PATH here.
if [[ -f "${DEST}/lib/pkgconfig/c-capnproto.pc" ]]; then
  sed -i.bak "s|^prefix=.*|prefix=${DEST}|" "${DEST}/lib/pkgconfig/c-capnproto.pc" 2>/dev/null \
    || sed -i '' "s|^prefix=.*|prefix=${DEST}|" "${DEST}/lib/pkgconfig/c-capnproto.pc"
  rm -f "${DEST}/lib/pkgconfig/c-capnproto.pc.bak"
fi

echo "ok: musl-static c-capnproto at ${DEST}"
