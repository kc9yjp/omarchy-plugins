# gdrive-backup

A simple home-directory backup: an hourly `rclone sync` mirror to Google
Drive, plus an Omarchy status-bar widget showing whether it's up to date —
implemented as a `command`-type custom bar module (see `bar.layout`'s
custom-module schema in `$OMARCHY_PATH/shell/plugins/bar/README.md`) and a
`systemd --user` timer, both symlinked into place so no packaged Omarchy
files are touched and it survives `omarchy update`.

Requires [`rclone`](https://rclone.org/) with a Google Drive remote already
configured (`rclone config`) — this plugin doesn't set one up for you.

## Behavior

- **`gdrive-backup-sync`** runs
  `rclone sync $HOME gdrive-boss:home-backup/$(hostname)` (a one-way
  *mirror* — files deleted locally are deleted from the remote too; Google
  Drive moves them to its own Trash rather than purging them immediately,
  but don't rely on that as your only safety net). The hostname in the
  path means multiple machines can share one Drive account without
  colliding. It's triggered by `gdrive-backup.timer` (hourly,
  `Persistent=true` so a missed run fires shortly after the next
  login/boot) or by clicking the widget.
- While running, it streams rclone's progress into
  `$XDG_STATE_HOME/gdrive-backup/current-run.log` (updated every 5s) so the
  widget can show live percentage/ETA instead of a static "syncing…". On
  completion that file becomes `last-run.log`, and the result (ok/error,
  timestamps, transfer summary) is written to `status.json`. A `flock` on
  `sync.lock` there prevents overlapping runs (a manual click while the
  timer is mid-run is a no-op, not a second sync).
- Before each sync, it walks the source tree for git repos (anything with a
  `.git` dir) and writes a `.gdrive-backup-git-info` file into each one with
  its origin remote URL and current branch — since `.git/**` itself is
  excluded from the mirror, this is the only record of what a project
  directory was once it's restored from a plain working-tree copy. The file
  is added to that repo's `.git/info/exclude` so it doesn't show up in
  `git status`.
- **`gdrive-backup`** (the bar widget) only reads that state — it never
  starts a sync itself. Icon is Nerd Font `cloud_upload`,  U+F0EE:
  - **syncing** — icon + live percentage (e.g. ` 42%`), normal color,
    tooltip shows the full rclone progress line (transferred/total, speed, ETA)
  - **up to date** — icon only, normal color, tooltip shows how long ago
    and the transfer summary
  - **stale** (no successful sync in `GDRIVE_BACKUP_STALE_SECS`, default 3h)
    — icon + `stale`, accent color — the timer probably isn't running
  - **error** — icon + `error`, accent color, tooltip shows the tail of the
    failure
  - **waiting** — icon + `waiting`, accent color — no sync has completed yet

## Install

```bash
./install.sh
```

This symlinks `gdrive-backup`, `gdrive-backup-sync`, and
`gdrive-backup.exclude` into `~/.config/omarchy/bar/scripts/`, symlinks
`gdrive-backup.service`/`.timer` into `~/.config/systemd/user/`, and enables
the timer. It also prints a warning if the default rclone remote
(`gdrive-boss:`) doesn't exist on this machine, and the `shell.json` snippet
to add:

```json
{
  "id": "gdrive-backup",
  "type": "command",
  "exec": "~/.config/omarchy/bar/scripts/gdrive-backup",
  "interval": 60,
  "onClick": "systemctl --user start gdrive-backup.service"
}
```

`shell.json` hot-reloads on save — no restart needed. If it doesn't pick up
immediately: `omarchy-shell shell rescanPlugins`.

Before trusting the hourly timer, run a sync manually once and check
`~/.local/state/gdrive-backup/last-run.log` — the first run walks all of
`$HOME` and can take a while depending on how much data and how it's
excluded:

```bash
~/.config/omarchy/bar/scripts/gdrive-backup-sync
```

## Configuration

Edit `gdrive-backup.exclude` (symlinked, so it's live — no reinstall
needed) to change what's skipped. Defaults exclude all top-level dotfiles
and dotdirs (`.config`, `.cache`, `.ssh`, `.mozilla`, `.bashrc`, etc. —
anchored to `$HOME` itself, so a nested repo's `.git` isn't caught by this
rule), `Downloads/**`, `.git`/`node_modules`/`venv`/`__pycache__` anywhere
in the tree, and large binary blobs (`*.iso`, `*.img`, `*.qcow2`). This is
a deliberately narrow default — only non-hidden folders like `Documents`,
`Pictures`, and project directories get backed up. Comment out `/.*` and
`/.*/**` if you want dotfiles included too.

Override the source directory, remote destination, or exclude file by
creating `~/.config/omarchy/bar/scripts/gdrive-backup.env` (picked up by
the systemd service via `EnvironmentFile=`):

```bash
GDRIVE_BACKUP_SOURCE=/home/you
GDRIVE_BACKUP_REMOTE=your-remote-name:home-backup/your-hostname
GDRIVE_BACKUP_EXCLUDE=/home/you/.config/omarchy/bar/scripts/gdrive-backup.exclude
```

Change the schedule by editing `gdrive-backup.timer`'s `OnCalendar=` (e.g.
`OnCalendar=*:0/30` for every 30 minutes) and running
`systemctl --user daemon-reload && systemctl --user restart gdrive-backup.timer`.

The bar widget's stale threshold defaults to 3 hours (2.5x the default
hourly cadence). If you change the timer interval, update the widget's
`exec` to match, e.g. for a 30-minute timer:

```bash
GDRIVE_BACKUP_STALE_SECS=5400 ~/.config/omarchy/bar/scripts/gdrive-backup
```

## Uninstall

```bash
systemctl --user disable --now gdrive-backup.timer
rm ~/.config/systemd/user/gdrive-backup.{service,timer}
rm ~/.config/omarchy/bar/scripts/gdrive-backup{,-sync,.exclude}
```

Then remove the `gdrive-backup` entry from `shell.json`'s `bar.layout`. The
Drive-side files under `gdrive-boss:home-backup/<hostname>` and the local
state in `~/.local/state/gdrive-backup/` are left in place — delete them
yourself if you want them gone too.
