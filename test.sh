#!/bin/bash
# Smoke check: every theme dir is complete, theme.env has the vars theme-set needs,
# and theme-set rejects unknown names. No config changes are made.
set -euo pipefail
cd "$(dirname "$0")"

for d in themes/*/; do
  for f in theme.env ghostty.conf tmux.conf atuin.toml lazygit.yml nvim.lua k9s.yaml starship.toml; do
    [ -f "$d$f" ] || { echo "MISSING $d$f"; exit 1; }
  done
  ( . "$d/theme.env"
    [ -n "$ZED_THEME" ] && [ -n "$NVIM_COLORSCHEME" ] && [ -n "$VICINAE_THEME" ] && { [ "$BACKGROUND" = dark ] || [ "$BACKGROUND" = light ]; } ) \
    || { echo "BAD env: $d"; exit 1; }
done

bin/theme-set no-such-theme >/dev/null 2>&1 && { echo "bogus name should fail"; exit 1; }
echo "OK: $(ls themes | wc -l | tr -d ' ') themes complete"
