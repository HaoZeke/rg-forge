#!/usr/bin/env bash

set -ex

# Install the package using pip
# This will automatically call setup.py, which runs cmake
# The conda build environment provides cmake, ninja, compilers, and libraries
# (liblapack, libblas) in the PATH and via environment variables.
$PYTHON -m pip install . --no-deps --no-build-isolation -vv
