#!/bin/bash
# One-time wiring: point app configs at ~/.config/themer/current. Idempotent; edits get .bak backups.
set -euo pipefail
REPO="$(cd "$(dirname "$0")" && pwd)"
CFG="$HOME/.config"

bk() { if [ -f "$1" ] && [ ! -f "$1.bak" ]; then cp "$1" "$1.bak"; fi; }

mkdir -p "$CFG/themer"

# --- ghostty: swap hardcoded theme for an include through the current symlink
bk "$CFG/ghostty/config"
if ! grep -q 'config-file = themer.conf' "$CFG/ghostty/config"; then
  sed -i '' 's|^theme = .*|config-file = themer.conf|' "$CFG/ghostty/config"
fi
ln -sfn "$CFG/themer/current/ghostty.conf" "$CFG/ghostty/themer.conf"

# --- tmux: disable catppuccin plugin styling, source the theme fragment instead
bk "$CFG/tmux/tmux.conf"
sed -i '' -e "s|^set -g @plugin 'catppuccin|# &|" -e "s|^set -g @catppuccin|# &|" "$CFG/tmux/tmux.conf"
if ! grep -q 'themer/current/tmux.conf' "$CFG/tmux/tmux.conf"; then
  printf '\n# themer: keep after the tpm run line; unset leftover plugin formats so theme styles show\nset -gu window-status-format\nset -gu window-status-current-format\nsource-file -q ~/.config/themer/current/tmux.conf\n' >> "$CFG/tmux/tmux.conf"
fi

# --- nvim: replace hardcoded colorscheme.lua with themer.lua (reads current/nvim.lua)
NV="$CFG/nvim/lua/plugins"
if [ -f "$NV/colorscheme.lua" ]; then
  mv "$NV/colorscheme.lua" "$NV/colorscheme.lua.bak" # .bak keeps it out of lazy.nvim's *.lua glob
fi
cat > "$NV/themer.lua" <<'EOF'
-- themer: colorscheme follows ~/.config/themer/current (repo: ~/Projects/themer)
local ok, t = pcall(dofile, vim.fn.expand("~/.config/themer/current/nvim.lua"))
t = ok and t or { colorscheme = "catppuccin-frappe", background = "dark" }
vim.o.background = t.background
return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    opts = {
      transparent_background = true,
      integrations = {
        cmp = true,
        gitsigns = true,
        nvimtree = true,
        telescope = true,
        treesitter = true,
        notify = false,
        mini = { enabled = true, indentscope_color = "" },
      },
    },
  },
  { "folke/tokyonight.nvim" },
  { "gbprod/nord.nvim" },
  { "navarasu/onedark.nvim" },
  { "ellisonleao/gruvbox.nvim" },
  { "rose-pine/neovim", name = "rose-pine" },
  { "maxmx03/solarized.nvim" },
  { "LazyVim/LazyVim", opts = { colorscheme = t.colorscheme } },
}
EOF

# --- atuin: stable theme name "themer" -> symlinked toml
bk "$CFG/atuin/config.toml"
mkdir -p "$CFG/atuin/themes"
ln -sfn "$CFG/themer/current/atuin.toml" "$CFG/atuin/themes/themer.toml"
if ! grep -q '^name = "themer"' "$CFG/atuin/config.toml"; then
  # comment out any active theme name first — a second `name` key is a TOML parse error
  sed -i '' -e 's|^name = |# name = |' -e '/^\[theme\]/a\
name = "themer"
' "$CFG/atuin/config.toml"
fi

# --- k9s: stable skin name "themer" -> symlinked skin
bk "$CFG/k9s/config.yaml"
ln -sfn "$CFG/themer/current/k9s.yaml" "$CFG/k9s/skins/themer.yaml"
sed -i '' 's|skin: .*|skin: themer|' "$CFG/k9s/config.yaml"

# --- lazygit: whole config is theme-only, symlink it (macOS config dir)
LG="$HOME/Library/Application Support/lazygit"
mkdir -p "$LG"
if [ -f "$LG/config.yml" ] && [ ! -L "$LG/config.yml" ]; then
  mv "$LG/config.yml" "$LG/config.yml.bak"
fi
ln -sfn "$CFG/themer/current/lazygit.yml" "$LG/config.yml"

# --- starship: marker-scoped palette only (never touches module config/format)
STAR="$CFG/starship.toml"
if [ -f "$STAR" ] && ! grep -q '^palette = "themer"' "$STAR"; then
  bk "$STAR"
  sed -i '' 's|^palette = |# palette = |' "$STAR"
  printf '# >>> themer palette (auto-managed) >>>\npalette = "themer"\n# <<< themer palette <<<\n\n' | cat - "$STAR" > "$STAR.tmp" && mv "$STAR.tmp" "$STAR"
  printf '\n# >>> themer palette table (auto-managed) >>>\n[palettes.themer]\n# <<< themer palette table <<<\n' >> "$STAR"
fi

# --- PATH
if ! grep -q 'Projects/themer/bin' "$HOME/.zshrc"; then
  echo 'export PATH="$HOME/Projects/themer/bin:$PATH"' >> "$HOME/.zshrc"
fi

# --- start on the theme everything already uses
"$REPO/bin/theme-set" catppuccin-frappe

cat <<'EOF'

Installed. One-time manual steps:
 1. Open nvim once -> lazy.nvim installs the new colorscheme plugins.
 2. In Zed (when installed): add theme extensions Tokyo Night, Nord, Solarized, Rose Pine.
 3. Open a new shell for PATH (theme-set / theme-list / theme-next).
 4. If Ghostty doesn't recolor on switch, press cmd+shift+, in Ghostty
    (or grant your terminal Accessibility access for the automatic reload).
EOF
