# Arch Astolfo desktop

The dark/pink Hyprland desktop, Kitty and Zsh theme, Waybar, Walker,
notification and GTK/Qt settings, wallpaper, fonts and terminal artwork.
The repository can also be used directly as `XDG_CONFIG_HOME`, as on the
original PC. Application accounts, histories, credentials and caches are ignored.

## Restore on another Arch PC

Start with an installed Arch system, a working graphics driver, networking,
Git and Python. This restores the user desktop; it does not partition disks,
install a bootloader, choose GPU drivers, or restore personal documents.

```sh
sudo pacman -Syu --needed git python
git clone https://github.com/Stefcio345/ArchAstolfoTheme.git ~/Dotfiles
cd ~/Dotfiles
./dotfiles packages --install
./dotfiles packages
```

Install the AUR packages printed by the last command using your preferred
AUR helper (or review and build their PKGBUILDs manually). Walker and its
Elephant providers supply the application launcher and clipboard menu.
The helper does not download and run an AUR bootstrap script.

Enable `ja_JP.UTF-8 UTF-8`, `en_US.UTF-8 UTF-8` and `pl_PL.UTF-8 UTF-8`
in `/etc/locale.gen`, then run `sudo locale-gen`. The Waybar clock uses
Japanese dates, and the default keyboard layout is Polish.

```sh
./dotfiles install --dry-run
./dotfiles install
./dotfiles check
chsh -s /usr/bin/zsh
```

Log out and select the Hyprland session when logging in. This configuration
uses the **Hyprland 0.55+ Lua API**; the original machine was running 0.56.2.
`hypr/hyprland.lua` is the maintained configuration; `hyprland.conf` is a
legacy reference for older installations, not the configuration to select.

The installer links only the paths in `config-paths.txt`, plus `~/.zshenv`
and `~/.local/bin/dotfiles`. Existing files, directories and even broken
symlinks are moved into `~/.local/state/dotfiles/backups/<timestamp>/`,
preserving their paths. Re-running it skips links that are already correct.
It never replaces the entire `~/.config` directory. To undo a link, remove
that specific symlink and move its matching backup back into place.

Shell startup resolves the clone location automatically, so a different
username or checkout name works. Desktop applications also find the files
through the installed links under `~/.config`. Keep the checkout in place;
if you move it, run the installer from its new location.

## Save and update

```sh
cd ~/Dotfiles
./dotfiles save -m "Adjust my theme"
```

This stages changes, checks staged files for common credential formats,
oversized files and nonportable dependencies/symlinks, commits, and pushes
to the configured upstream. A failed push leaves the commit safely local;
fix authentication or connectivity and run the command again. Use
`./dotfiles save --no-push -m "Work in progress"` for an offline commit.
You can also use normal `git status`, `git add`, `git commit` and `git push`.
The checks catch common mistakes; inspect `git diff` before sharing changes.

After opening a new shell, `dotfiles save -m "Adjust my theme"` also works
from any directory. GitHub authentication is configured separately on each
PC. For SSH pushes after cloning with HTTPS:

```sh
git remote set-url origin git@github.com:Stefcio345/ArchAstolfoTheme.git
```

On another configured PC, run `git pull --ff-only` in the checkout. Linked
settings update immediately on disk; reload the affected app or log in again.
Run the installer again if a later commit adds new managed paths.

## Hardware and private overrides

Fresh clones use preferred monitor modes and automatic placement, without
forcing NVIDIA variables. The original desktop layout is saved in
`hosts/franke-desktop.lua`; Waybar hardware settings are in the matching
`.env` profile. To recreate that particular machine:

```sh
cp hosts/franke-desktop.lua hypr/local.lua
cp hosts/franke-desktop.env waybar/local.env
```

On different hardware, edit your own `hypr/local.lua` and `waybar/local.env`
using those examples. These files are ignored, so they survive normal pulls
without changing the shared theme. Use `hyprctl monitors`, `wpctl status`
and `ddcutil detect` to find your outputs, audio devices and DDC buses.
Without audio device overrides, the custom switch may need adjustment;
the regular volume control and Pavucontrol remain available. External
monitor brightness needs DDC/CI enabled in the monitor and working I2C access.

Private shell aliases belong in `zsh/local.zsh` (ignored). Small vendored
copies of Oh My Zsh, autosuggestions, syntax highlighting and hyprsplit
are included with their licenses, so a normal clone needs no submodules.
Their upstream versions are recorded in `packages/vendor-sources.md`.
Zsh completion definitions come from Arch's `zsh-completions` package.

Seal and Jushot are custom applications installed separately on the original
PC. When absent, the keybindings use Thunar and Hyprshot. The optional F1
clicker runs only if `~/Scripts/clicker.sh` exists. OpenRGB profiles and GPU
drivers are hardware specific and are not restored by this repository.

Only the active wallpaper and static image collection are included; unused
wallpaper videos and personal files are not needed to reproduce this theme.
Arch is rolling release: package names are listed in `packages/`, and the
observed dependency versions are recorded for reference, not pinned as a
complete operating system image.

## Verify changes

The Kitty background now uses a resize watcher to anchor the existing
artwork's four corners in wide and portrait windows. Its generated size
variants live in the user cache; the source artwork stays in Git. Open a
new Kitty window once after first installing the watcher. Fastfetch sizes
each picture using its aspect ratio and the terminal's cell dimensions;
short terminals use a compact greeting so the image stays visible. The
welcome is a single text line, followed by a centered image/info panel and
a small divider. Very thin windows show just a centered picture, with no
wrapped system text. Wider panels measure their text to keep a clear margin
beside the corner ornament, and explicitly reserve rows for the prompt.
Resizing redraws only the welcome screen (preserving partially typed input);
after the first command,
your output is preserved. The prompt shows a command's actual failure status
and keeps the directory, Git branch and clock compact. The right-hand clock
refreshes when a command is submitted and stays beside it in scrollback.

```sh
./dotfiles check
python -m unittest discover -s tests -v
```

Installer tests use temporary home directories and cover dry runs, backups,
repeat installs and a checkout with spaces in its path.

## Ideas

- [ ] Quickshell implementation
- [ ] Wi-Fi and Bluetooth widgets
- [ ] Calendar and AI widgets
- [ ] Micro keybinds
- [ ] Wallpaper picker
