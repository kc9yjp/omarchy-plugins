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

## Setting up a new machine

Restores configs from another machine's Drive backup, then reinstalls the
plugins. Assumes a fresh Omarchy install with the **same username**. The
restored `~/.config/omarchy/bar/scripts/*` symlinks are absolute paths into
`/home/<user>/Work/omarchy-plugins`.

1. **Clone this repo to the same path:**

   ```bash
   mkdir -p ~/Work && git clone https://github.com/kc9yjp/omarchy-plugins.git ~/Work/omarchy-plugins
   ```

2. **Install rclone and connect Google Drive.** rclone isn't part of a
   default Omarchy install. Name the remote `gdrive-boss` so the defaults
   work, otherwise see `gdrive-backup.env` in the gdrive-backup README:

   ```bash
   sudo pacman -S --needed rclone
   rclone config     # n → name: gdrive-boss → storage: drive → browser OAuth
   ```

3. **Pull the old machine's configs down.** Backups live under
   `home-backup/<hostname>`. List them with `rclone lsd gdrive-boss:home-backup`
   and use the old machine's hostname. Move each fresh default aside first:

   ```bash
   for p in omarchy hypr; do
     [[ -e ~/.config/$p ]] && mv ~/.config/$p ~/.config/$p.bak.$(date +%s)
     rclone copy gdrive-boss:home-backup/<old-hostname>/.config/$p ~/.config/$p
   done
   hyprctl reload
   ```

   `omarchy` brings the bar layout (`shell.json`), themes, hooks, and the
   third-party plugins (`~/.config/omarchy/plugins/`) along with it.

   **`hypr` includes machine-specific monitor config** (`monitors.conf`,
   `monitors.lua`, `hyprmoncfg-monitors.lua`). After restoring, fix monitor
   names and resolutions for the new hardware (`hyprctl monitors`), or
   copy the new machine's defaults back from the `.bak` directory.

4. **Reinstall the plugins:** `gdrive-backup/install.sh` (enables the
   hourly backup for *this* machine's hostname) and `disk-usage/install.sh`.
   Each one relinks its scripts in place. Skip the `shell.json` snippets
   they print if you restored `omarchy` in step 3, because the layout is
   already there.

## Adding a new plugin

1. `mkdir <name> && cd <name>`
2. Write the script, an `install.sh` that symlinks it into place, and a
   `README.md` covering behavior and the `shell.json` wiring.
3. Run `./install.sh` to link it live.
4. Add an entry to the Plugins list above.
