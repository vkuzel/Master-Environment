#!/bin/bash

tmpDir=$(mktemp -d)

cat >"$tmpDir/.zshrc" <<'EOF'

source "$HOME/.config/zsh/.zshrc.key-bindings.zsh"
source "$HOME/.config/zsh/.zshrc.aliases.zsh"

PROMPT='[%F{red}docker%f]%F{green}%n@%m%f:%F{yellow}%~%f %# '
EOF

sudo --preserve-env \
  ZDOTDIR="$tmpDir" \
  setpriv \
    --reuid "$(id -u)" \
    --regid "$(id -g)" \
    --groups "$(id -G | tr ' ' ','),$(getent group docker | cut -d: -f3)" \
    zsh -i

rm -r "$tmpDir"
