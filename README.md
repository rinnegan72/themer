# themer

[Omarchy](https://omarchy.org)-style theme switching for macOS: one command re-themes every app, live.

```
theme-set tokyo-night
```

## How it works

`~/.config/themer/current` is a symlink to one of the `themes/<name>/` directories. Each app reads its colors *through* that symlink — via a config include (Ghostty, tmux) or a symlinked theme file (atuin, k9s, lazygit) — so switching themes is one `ln -sfn` plus reloads. Only Zed needs its `settings.json` edited per switch.

| App | Mechanism | Reload |
|---|---|---|
| Ghostty | `config-file = themer.conf` → built-in theme name | osascript clicks its Reload Configuration menu (fallback: cmd+shift+,) |
| tmux | `source-file` of the theme fragment | `tmux source-file`, instant |
| nvim (LazyVim) | `lua/plugins/themer.lua` reads `current/nvim.lua` | `--remote-send` to every running instance, instant |
| Zed | rewrites the `"theme"` object in settings.json | Zed hot-reloads, instant |
| Vicinae | `vicinae-cli theme set <built-in name>` | applied by the server, instant |
| atuin | `themes/themer.toml` symlink | next launch |
| k9s | `skins/themer.yaml` symlink | next launch |
| lazygit | whole `config.yml` is a symlink | next launch |
| starship | nothing — default prompt uses ANSI colors, follows the terminal palette | free |

## Themes

catppuccin-frappe · catppuccin-latte · gruvbox-dark · gruvbox-light · nord · one-dark · rose-pine · rose-pine-dawn · solarized-dark · solarized-light · tokyo-night

Ghostty uses its bundled themes, nvim uses the usual colorscheme plugins, k9s skins come from upstream ([derailed/k9s](https://github.com/derailed/k9s/tree/master/skins), [axkirillov/k9s-tokyonight](https://github.com/axkirillov/k9s-tokyonight)); tmux/atuin/lazygit fragments are hand-written from each theme's published palette.

## Install

```
git clone https://github.com/rinnegan72/themer ~/Projects/themer
cd ~/Projects/themer && ./install.sh
```

`install.sh` is idempotent and backs up every config it touches to `<file>.bak`. It expects the apps above configured in their usual places; missing apps just mean that step is irrelevant.

## Usage

```
theme-set <name>   # switch everything
theme-list         # list themes, * marks current
theme-next         # cycle
./test.sh          # smoke check
```

## Adding a theme

Copy any `themes/<name>/` directory and swap the palette:

```
theme.env      # ZED_THEME, NVIM_COLORSCHEME, VICINAE_THEME, BACKGROUND=dark|light
ghostty.conf   # theme = <a `ghostty +list-themes` name>
nvim.lua       # colorscheme + background
tmux.conf      # status/pane/message styles
atuin.toml     # 8 color keys
lazygit.yml    # gui.theme block
k9s.yaml       # a k9s skin
```
