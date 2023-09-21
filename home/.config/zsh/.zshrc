
autoload -U colors && colors
LSCOLORS='xefxcxdxbxegedabagacad'

EDITOR=vi
PAGER=less

autoload -U compinit && compinit

source "$HOME/.config/zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
source "$HOME/.config/zsh/zsh-autosuggestions/zsh-autosuggestions.zsh"
source "$HOME/.config/zsh/zsh-history-substring-search/zsh-history-substring-search.zsh"

alias l="LSCOLORS='Exfxcxdxbxegedabagacad' ls -Gl"
alias ll='LSCOLORS='Exfxcxdxbxegedabagacad' ls -GlA'
alias mc='LANG=C mc'
alias uuidgen-lower="uuidgen | tr '[:upper:]' '[:lower:]'"
alias cdd="cd $HOME/Downloads"
alias cdD="cd $HOME/Google Drive/Documents"
alias cdp="cd $HOME/projects"

bindkey '^[^[[D' backward-word
bindkey '^[^[[C' forward-word
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# mixins
[ -f "$HOME/.config/zsh/.zshrc.mixins.zsh" ] && source "$HOME/.config/zsh/.zshrc.mixins.zsh"

# starship prompt
export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"
eval "$(starship init zsh)"

