#!/bin/bash
# Installs the disk-usage bar widget by symlinking it into
# ~/.config/omarchy/bar/scripts/, then prints the shell.json snippet
# needed to add it to the bar.
set -euo pipefail

plugin_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
target_dir="$HOME/.config/omarchy/bar/scripts"
target="$target_dir/disk-usage"

mkdir -p "$target_dir"

if [[ -L "$target" ]]; then
  ln -sf "$plugin_dir/disk-usage" "$target"
  echo "Updated symlink: $target -> $plugin_dir/disk-usage"
elif [[ -e "$target" ]]; then
  echo "Refusing to overwrite existing non-symlink file: $target" >&2
  exit 1
else
  ln -s "$plugin_dir/disk-usage" "$target"
  echo "Linked: $target -> $plugin_dir/disk-usage"
fi

chmod +x "$plugin_dir/disk-usage"

cat <<'EOF'

Add this module to a section of bar.layout in ~/.config/omarchy/shell.json
(it hot-reloads on save, no restart needed):

  {
    "id": "disk-usage",
    "type": "command",
    "exec": "~/.config/omarchy/bar/scripts/disk-usage",
    "interval": 60
  }

See README.md for behavior details and the DISK_USAGE_MOUNT override.
EOF
