# omadot

Installs [omadot](https://github.com/tomhayes/omadot), a small
[GNU Stow](https://www.gnu.org/software/stow/) wrapper that turns
individual configs into packages under `~/.dotfiles` so they can be backed
up and restored one at a time on another Omarchy machine.

omadot itself has no cloud sync. Here, `~/.dotfiles` is mirrored to Google
Drive by the [`gdrive-backup`](../gdrive-backup/) plugin (its filter file
carves `/.dotfiles/**` back in). You can also make `~/.dotfiles` a private
git repo if you want history.

## Install

```bash
sudo pacman -S --needed stow
./install.sh
```

`install.sh` downloads the omadot script, pinned to a reviewed upstream
commit, into `~/.local/bin/omadot`. Upstream ships no license, so the
script isn't vendored here. To upgrade, read the upstream diff, then bump
`OMADOT_COMMIT` in `install.sh` and rerun it.

## Usage

```bash
omadot get hypr            # mv ~/.config/hypr -> ~/.dotfiles/hypr/.config/hypr
omadot put hypr            # symlink ~/.config/hypr -> ~/.dotfiles/...
omadot get .bashrc --home  # files in ~ instead of ~/.config
omadot list
```

`get` really moves the directory, and `put` symlinks it back. Run them as
a pair, otherwise the app loses its config until you run `put`.

Start with the configs you actually customize (`hypr`, `omarchy`,
`waybar`, `walker`, your terminal, …). Avoid `omadot get --all`, which
also scoops up browser profiles, caches, and app credentials.

## Restoring on another machine

1. Pull the old machine's backup down from Drive. Backups are namespaced
   by hostname:

   ```bash
   rclone copy gdrive-boss:home-backup/<old-hostname>/.dotfiles ~/.dotfiles
   ```

2. Install omadot and stow (above).
3. Restore just the pieces you want. Stow refuses to overwrite a real
   directory, so move the new machine's default config aside first:

   ```bash
   mv ~/.config/hypr ~/.config/hypr.bak.$(date +%s)
   omadot put hypr
   ```

## Caveats

- Configs become directory symlinks into `~/.dotfiles`. Omarchy's
  `omarchy-refresh-config` copies individual files (`cp -f`) through the
  symlink, so a refreshed default and its `.bak.<timestamp>` both land in
  `~/.dotfiles`. That's fine, just expect the `.bak` files to show up in
  the backup.
- Anything you `get` lands in `~/.dotfiles` and gets uploaded to Drive.
  Check each package for tokens or keys first.
