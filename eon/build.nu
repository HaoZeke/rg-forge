let host_prefix_expanded = ($env.PREFIX | path expand)
# Create the "native.ini" file to explicitly tell Meson which Python to use.
# This hard-codes the path to the correct Python from the conda host environment.
let python_path = ($env.PREFIX | path join 'bin/python')
let content = $"[binaries]\npython = '($python_path)'\n"
$content | save native.ini

if ($env.WITH_METATOMIC == "1"){
# --- Add Vesin paths to the environment ---
# Get the site-packages path from the host python
let site_packages = (^$python_path -c "import sysconfig; print(sysconfig.get_path('platlib'))")

# Construct the full paths to vesin's include and lib dirs
let vesin_include = ($site_packages | path join 'vesin/include')
let vesin_lib = ($site_packages | path join 'vesin/lib')

# Prepend these paths to the compiler/linker flags
# Use `default ""` in case the variables don't exist yet.
$env.CPPFLAGS = $"-I($vesin_include) ($env.CPPFLAGS? | default "")"
$env.LDFLAGS = $"-L($vesin_lib) ($env.LDFLAGS? | default "")"
}

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
        # TODO(rg): Handle vesin better
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
