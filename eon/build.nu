let host_prefix_expanded = ($env.PREFIX | path expand)
# Create the "native.ini" file to explicitly tell Meson which Python to use.
# This hard-codes the path to the correct Python from the conda host environment.
let python_path = ($env.PREFIX | path join 'bin/python')
let content = $"[binaries]\npython = '($python_path)'\n"
$content | save native.ini

# --- Configure ---
let configure_args = [
    $"--prefix=($host_prefix_expanded)",
    "--libdir=lib",
    "--buildtype=release",
    "-Dpython.install_env=prefix",
    # Needed to pin the right Python file
    "--native-file", "native.ini",
    # Handling conditionals
    ...(if ($env.WITH_LAMMPS == "1") {
        ["-Dwith_lammps=True"]
    } else {
        []
    })
    ...(if ($env.WITH_METATOMIC == "1") {
        [
        "-Dwith_metatomic=True",
        "-Dpip_metatomic=False"
        $"-Dtorch_path=($host_prefix_expanded)"
        ]
    } else {
        []
    })
]

print $"INFO: Running meson setup with ($configure_args | str join ' ')"
# External commands will get LIBS, CPPFLAGS, CXXFLAGS as space-separated strings
# due to the to_string closure in ENV_CONVERSIONS.
meson setup bbdir ...$configure_args
meson install -C bbdir
