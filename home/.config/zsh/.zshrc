
# colors

autoload -U colors && colors
LSCOLORS='xefxcxdxbxegedabagacad'

# default apps

EDITOR=vi
PAGER=less

# options

autoload -U compinit && compinit

# plugins

source "$HOME/.config/zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
source "$HOME/.config/zsh/zsh-autosuggestions/zsh-autosuggestions.zsh"
source "$HOME/.config/zsh/zsh-history-substring-search/zsh-history-substring-search.zsh"

# aliases

alias l="LSCOLORS='Exfxcxdxbxegedabagacad' ls -Gl"
alias ll='LSCOLORS='Exfxcxdxbxegedabagacad' ls -GlA'
alias mc='LANG=C mc'
alias uuidgen-lower="uuidgen | tr '[:upper:]' '[:lower:]'"
alias cdd="cd $HOME/Downloads"
alias cdD="cd $HOME/Google Drive/Documents"
alias cdp="cd $HOME/projects"

# keybindings

bindkey '^[^[[D' backward-word
bindkey '^[^[[C' forward-word
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line

# george utils

source "$HOME/projects/george-utils/env.sh"

# Set PATH, MANPATH, etc., for Homebrew.
eval "$(/opt/homebrew/bin/brew shellenv)"

# PyEnv
export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# Copied from generated .bash_profile file
export GEM_HOME="$HOME/.gem"
export PATH="$GEM_HOME/bin:$PATH"
export PATH="$HOME/.rbenv/bin:$PATH"
export RBENV_ROOT="$HOME/.rbenv"
eval "$(rbenv init -)"

# starship prompt

export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"
eval "$(starship init zsh)"


