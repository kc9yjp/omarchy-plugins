#!/bin/bash
# Installs omadot (https://github.com/tomhayes/omadot), a GNU Stow wrapper
# for managing dotfiles as per-app packages under ~/.dotfiles:
#   - downloads the omadot script, pinned to a reviewed commit, into
#     ~/.local/bin (no sudo — unlike upstream's installer, which uses
#     /usr/local/bin)
#   - checks that GNU Stow is installed
#
# Not vendored into this repo: upstream ships no license file.
#
# To move to a newer upstream version, read the diff first, then bump
# OMADOT_COMMIT:
#   https://github.com/tomhayes/omadot/compare/<old>...main
set -euo pipefail

OMADOT_COMMIT="${OMADOT_COMMIT:-69199890496fa6afa975342b2379f525e0e5ddea}"
bin_dir="$HOME/.local/bin"
dest="$bin_dir/omadot"
url="https://raw.githubusercontent.com/tomhayes/omadot/$OMADOT_COMMIT/omadot"

mkdir -p "$bin_dir"
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

curl -fsSL "$url" -o "$tmp"
install -m 755 "$tmp" "$dest"
echo "Installed omadot ($OMADOT_COMMIT) to $dest"

if ! command -v stow &>/dev/null; then
  cat <<'EOF'

WARNING: GNU Stow is not installed — `omadot put` needs it. Install with:

  sudo pacman -S --needed stow

EOF
fi

cat <<'EOF'

Next steps (see README.md):
  omadot get hypr          # move ~/.config/hypr into ~/.dotfiles/hypr
  omadot put hypr          # symlink it back into place
  omadot list

~/.dotfiles is backed up to Google Drive by the gdrive-backup plugin.
EOF
