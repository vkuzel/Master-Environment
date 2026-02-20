EDITOR=vi
PAGER=less

alias ls='ls --color=auto'
alias l="ls -l"
alias ll='ls -lA'
alias grep='grep --color=auto'
alias vi='nvim'
alias bc='bc -l'
# Most servers does not recognize "foot" terminal
alias ssh='TERM=xterm-256color ssh'
alias uuidgen-lower="uuidgen | tr '[:upper:]' '[:lower:]'"
alias cdd="cd $HOME/Downloads"
alias cdD="cd $HOME/Documents"
alias cdp="cd $HOME/projects"
# get keys by running `showkey -a`
bindkey -e
bindkey '^[[1;5D' backward-word
bindkey '^[[1;5C' forward-word
bindkey '^H' backward-kill-word
bindkey "^[[3;5~" kill-word
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

autoload -U colors && colors
[ -x /usr/bin/dircolors ] && eval "$(dircolors -b)"

autoload -U compinit && compinit

source "$HOME/.config/zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
source "$HOME/.config/zsh/zsh-autosuggestions/zsh-autosuggestions.zsh"
source "$HOME/.config/zsh/zsh-history-substring-search/zsh-history-substring-search.zsh"
# mixins
[ -f "$HOME/.config/zsh/.zshrc.mixins.zsh" ] && source "$HOME/.config/zsh/.zshrc.mixins.zsh"

# starship prompt
export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"
eval "$(starship init zsh)"

