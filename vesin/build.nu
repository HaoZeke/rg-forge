#!/usr/bin/env nu

let host_prefix_expanded = ($env.PREFIX | path expand)
if ($env.USE_SCCACHE == "1") {
   $env.CMAKE_C_COMPILER_LAUNCHER = "sccache"
   $env.CMAKE_CXX_COMPILER_LAUNCHER = "sccache"
}

(cmake -S . -B build
          -DCMAKE_BUILD_TYPE=Release
          -DPACKAGE_TESTS=ON -DNO_WARN=TRUE)
let cpu_count = $env.CPU_COUNT? | default (sys cpu | length)
print $"INFO: Running make -j($cpu_count)"
cmake --build build $"-j($cpu_count)"
cmake --install build --prefix $"($host_prefix_expanded)"
