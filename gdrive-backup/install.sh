#!/bin/bash
# Installs the gdrive-backup plugin:
#   - symlinks the bar widget, sync script, and exclude file into
#     ~/.config/omarchy/bar/scripts/
#   - symlinks the systemd --user service+timer into ~/.config/systemd/user/
#     and enables the timer (hourly mirror to Google Drive)
#   - prints the shell.json snippet needed to add the bar widget
set -euo pipefail

plugin_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bar_scripts_dir="$HOME/.config/omarchy/bar/scripts"
systemd_user_dir="$HOME/.config/systemd/user"

mkdir -p "$bar_scripts_dir" "$systemd_user_dir"

link() {
  local src="$1" dest="$2"
  if [[ -L "$dest" ]]; then
    ln -sf "$src" "$dest"
    echo "Updated symlink: $dest -> $src"
  elif [[ -e "$dest" ]]; then
    echo "Refusing to overwrite existing non-symlink file: $dest" >&2
    exit 1
  else
    ln -s "$src" "$dest"
    echo "Linked: $dest -> $src"
  fi
}

link "$plugin_dir/gdrive-backup" "$bar_scripts_dir/gdrive-backup"
link "$plugin_dir/gdrive-backup-sync" "$bar_scripts_dir/gdrive-backup-sync"
link "$plugin_dir/gdrive-backup.exclude" "$bar_scripts_dir/gdrive-backup.exclude"
chmod +x "$plugin_dir/gdrive-backup" "$plugin_dir/gdrive-backup-sync"

link "$plugin_dir/gdrive-backup.service" "$systemd_user_dir/gdrive-backup.service"
link "$plugin_dir/gdrive-backup.timer" "$systemd_user_dir/gdrive-backup.timer"

systemctl --user daemon-reload
systemctl --user enable --now gdrive-backup.timer
echo "Enabled gdrive-backup.timer (runs hourly, plus on next login if a run was missed)"

# Sanity-check that the default remote's rclone remote actually exists.
default_remote="gdrive-boss:home-backup/$(hostname)"
remote_name="${default_remote%%:*}"
if ! rclone listremotes 2>/dev/null | grep -qx "${remote_name}:"; then
  cat <<EOF

WARNING: rclone has no remote named '${remote_name}:'. Run 'rclone config'
to set up a Google Drive remote, or point gdrive-backup at an existing one
by creating $bar_scripts_dir/gdrive-backup.env with:

  GDRIVE_BACKUP_REMOTE=your-remote-name:home-backup/$(hostname)

EOF
fi

cat <<'EOF'

Add this module to a section of bar.layout in ~/.config/omarchy/shell.json
(it hot-reloads on save, no restart needed):

  {
    "id": "gdrive-backup",
    "type": "command",
    "exec": "~/.config/omarchy/bar/scripts/gdrive-backup",
    "interval": 60,
    "onClick": "systemctl --user start gdrive-backup.service"
  }

Left-click runs a sync immediately; the widget itself just displays status
and never triggers one.

See README.md for status states, the exclude list, and how to override the
source/remote/stale-threshold.
EOF
