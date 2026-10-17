# omarchy-plugins

Personal collection of [Omarchy](https://omarchy.org/) status-bar plugins
and other shell customizations, each kept as user-owned config (never
editing `/usr/share/omarchy/`) so they survive `omarchy update`.

## Layout

Each subdirectory is one self-contained plugin:

```
<plugin-name>/
  README.md      what it does, config options
  install.sh      symlinks it into place and prints any shell.json snippet needed
  <script(s)>     the plugin itself
```

`install.sh` symlinks the script(s) into their live location under
`~/.config/omarchy/`, so editing a file in this repo takes effect
immediately (via `omarchy-shell shell rescanPlugins` or the bar's own
hot-reload) — no separate copy step.

## Plugins

- [`disk-usage`](disk-usage/) — bar widget showing disk used/free space,
  hidden until usage crosses 80%, accent-colored above 90%.
- [`gdrive-backup`](gdrive-backup/) — hourly `rclone` mirror of the home
  directory to Google Drive, with a bar widget showing sync status
  (up to date / syncing / stale / error) and click-to-sync-now.
- [`omadot`](omadot/) — installs omadot (GNU Stow wrapper) to manage
  configs as per-app packages in `~/.dotfiles`, backed up by
  `gdrive-backup` and restorable one at a time on another machine.

## Adding a new plugin

1. `mkdir <name> && cd <name>`
2. Write the script, an `install.sh` that symlinks it into place, and a
   `README.md` covering behavior and the `shell.json` wiring.
3. Run `./install.sh` to link it live.
4. Add an entry to the Plugins list above.
