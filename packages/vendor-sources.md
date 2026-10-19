# Included source dependencies

These files are ordinary tracked files, not Git submodules. Original
checkouts, if present on the first PC, remain untouched and ignored.

| Source | Revision | Included files |
| --- | --- | --- |
| https://github.com/ohmyzsh/ohmyzsh | `48feb570f7b7d80cc7554629ba428c520ea8a3d5` | Loader, libraries, tools, git plugin, bundled zsh-autosuggestions and zsh-syntax-highlighting, and licenses under `zsh/vendor/ohmyzsh` |
| https://github.com/shezdy/hyprsplit | `6b00b677d8905fb38779c91e12d6294e0e586a44` | Lua module, README and license under `hypr/lib/hyprsplit` |

Oh My Zsh automatic updates are disabled to keep the restored theme
consistent with Git. Update these snapshots deliberately, preserve their
licenses, test shell startup and Hyprland, and commit the new revision.
