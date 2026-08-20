#!/usr/bin/env bash
set -u -o pipefail

output_dir=${1:?output directory is required}
channel=${2:?channel is required}
manifest=${3:?manifest path is required}

mkdir -p "$(dirname "$manifest")"
: >"$manifest"

mapfile -d '' packages < <(
  find "$output_dir" -type f \( -name '*.conda' -o -name '*.tar.bz2' \) -print0 | sort -z
)

if ((${#packages[@]} == 0)); then
  printf 'failed\tNO_PACKAGES\n' >"$manifest"
  echo "no packages found under $output_dir" >&2
  exit 1
fi

status=0
for pkg in "${packages[@]}"; do
  if rattler-build upload prefix --skip-existing -c "$channel" "$pkg"; then
    printf 'uploaded\t%s\n' "$pkg" >>"$manifest"
  else
    printf 'failed\t%s\n' "$pkg" >>"$manifest"
    status=1
  fi
done

exit "$status"
