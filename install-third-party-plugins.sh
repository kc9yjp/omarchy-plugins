#!/bin/bash
# Install and enable the third-party Omarchy plugins used on the source machine.
# Plugins already present (e.g. restored with `omadot put omarchy`) are not
# re-cloned, only enabled if needed. Nothing is removed or disabled.

set -euo pipefail

# id=git-url
plugins=(
  furmware.cloud=https://github.com/JoshuaFurman/omarchy-cloud-plugin.git
  io.github.arikisonfire.rsync=https://github.com/arikisonfire/omarsync.git
  io.github.e2goon.omasweep=https://github.com/e2goon/omasweep.git
  jampick.protonvpn=https://github.com/jampick/omarchy-protonvpn.git
)

command -v omarchy >/dev/null || { echo "omarchy not found" >&2; exit 1; }
command -v jq >/dev/null || { echo "jq not found" >&2; exit 1; }

failed=0

for entry in "${plugins[@]}"; do
  id=${entry%%=*}
  url=${entry#*=}
  state=$(omarchy plugin list --json |
    jq -r --arg id "$id" 'first(.[] | select(.id == $id) | .enabled) // "missing"')
  case $state in
    true) echo "ok         $id" ;;
    false)
      if omarchy plugin enable "$id" >/dev/null; then
        echo "enabled    $id"
      else
        echo "FAILED     $id (enable)"; failed=1
      fi
      ;;
    missing)
      if omarchy plugin add "$url" --enable --yes >/dev/null; then
        echo "installed  $id"
      else
        echo "FAILED     $id (add $url)"; failed=1
      fi
      ;;
  esac
done

exit $failed
