#!/bin/bash
# Enable the first-party Omarchy plugins that are enabled on the source machine.
# Already-enabled plugins are skipped; nothing is disabled.

set -euo pipefail

plugins=(
  omarchy.agents omarchy.audio omarchy.background omarchy.battery
  omarchy.bluetooth omarchy.clipboard omarchy.clock omarchy.dev-gallery
  omarchy.disk-speedtest omarchy.monitor omarchy.dropbox omarchy.emojis
  omarchy.idle omarchy.image-picker omarchy.indicators omarchy.keyboard-layout
  omarchy.lock omarchy.network omarchy.nightlight omarchy.notifications
  omarchy.menu omarchy.system-update omarchy.osd omarchy.polkit omarchy.power
  omarchy.reminders omarchy.speedtest omarchy.tray omarchy.tailscale
  omarchy.weather omarchy.wifiqr omarchy.workspaces
)

command -v omarchy >/dev/null || { echo "omarchy not found" >&2; exit 1; }
command -v jq >/dev/null || { echo "jq not found" >&2; exit 1; }

catalog=$(omarchy plugin list --json)
failed=0

for id in "${plugins[@]}"; do
  state=$(jq -r --arg id "$id" 'first(.[] | select(.id == $id) | .enabled) // "missing"' <<<"$catalog")
  case $state in
    true)    echo "ok       $id" ;;
    missing) echo "missing  $id (not available on this Omarchy version)"; failed=1 ;;
    *)
      if omarchy plugin enable "$id" >/dev/null; then
        echo "enabled  $id"
      else
        echo "FAILED   $id"; failed=1
      fi
      ;;
  esac
done

exit $failed
