# Gothic terminal background v4

Revision of `gothic-watermark-v3.png`, generated with the built-in image
generation tool. The original wide background supplies the reference for
the restored heart, chain, bow and filigree corner decorations.

Asset: `gothic-corners-v4.png`, selected in `kitty-astolfo-goth.conf`
and `../themes/AstolfoTheme.conf`.

The crest sits farther to the right, leaving the left typing area open.
The static source targets the original desktop's approximately 924 x 976
terminal windows. `responsive_background.py` is now loaded as a Kitty
watcher: it reuses this artwork and lays the four corner ornaments and
crest out independently for the actual window dimensions. Wide windows
therefore retain the corners without stretching their shapes. The rendered
canvases are cached under `~/.cache/astolfo-goth/responsive-backgrounds/`,
with at most 32 size variants retained. `cscaled` remains the static fallback.
Kitty no longer draws an extra pink border around the terminal pane.

Open a new Kitty window once after adding the watcher; existing windows do
not acquire new global watchers merely by reloading the configuration.

## Generation prompt

undefined
