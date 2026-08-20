# disk-usage

An Omarchy status-bar widget showing disk used/free space, implemented as a
`command`-type custom bar module (see `bar.layout`'s custom-module schema in
`$OMARCHY_PATH/shell/plugins/bar/README.md`) — no packaged Omarchy files are
touched, so it survives `omarchy update`.

## Behavior

- Runs `df` against a mount point (`/` by default) and prints Waybar-style
  JSON (`{text, tooltip, class}`) for the bar to render.
- **< 80% used** — icon only (Nerd Font `harddisk`,  U+F02CA), normal color.
  Hovering still shows the full tooltip.
- **80–90% used** — icon + free space (e.g. `󰋊 11G`), normal color.
- **≥ 90% used** — same, but rendered in the bar's accent/urgent color
  (`class: "active"` — the only class value Omarchy's bar treats specially).
- **df failure** (bad mount, etc.) — icon + `disk` in accent color, tooltip
  explains the error.

## Install

```bash
./install.sh
```

This symlinks `disk-usage` into `~/.config/omarchy/bar/scripts/disk-usage`
and prints the `shell.json` snippet to add. Add the module to a section of
`bar.layout` in `~/.config/omarchy/shell.json`:

```json
{
  "id": "disk-usage",
  "type": "command",
  "exec": "~/.config/omarchy/bar/scripts/disk-usage",
  "interval": 60
}
```

`shell.json` hot-reloads on save — no restart needed. If it doesn't pick
up immediately: `omarchy-shell shell rescanPlugins`.

## Configuration

Override the mount point with an environment variable (set it in the
`exec` command if you want a non-default mount):

```bash
DISK_USAGE_MOUNT=/home ~/.config/omarchy/bar/scripts/disk-usage
```
