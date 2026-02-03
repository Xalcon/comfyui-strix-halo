#!/bin/sh
set -eu

BASE=$(pwd)

# filling mounted directories from .default.<template> directories
for d in blueprints user custom_nodes models input output; do
  src="$BASE/.default.$d"
  dst="$BASE/$d"

  [ -d "$src" ] || continue

  mkdir -p "$dst"

  # Copy only missing files/directories, recursively
  cp -a -n "$src/." "$dst/"
done


comfy launch
