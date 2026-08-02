#!/usr/bin/env nu

let prefix = ($env.PREFIX | path expand)
let cpu_count = $env.CPU_COUNT? | default (sys cpu | length)

# Meson cross-friendly: use conda compilers from env.
# both: shared for image/FHS consumers + static for dogfood embed (libcapnp_c.a).
(meson setup build
  --prefix $prefix
  --libdir lib
  --buildtype release
  -Ddefault_library=both
  -Denable_tests=false
  --wrap-mode=nofallback)

print $"INFO: meson compile -j($cpu_count)"
meson compile -C build $"-j($cpu_count)"
meson install -C build
