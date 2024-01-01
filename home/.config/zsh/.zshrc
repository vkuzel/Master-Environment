
autoload -U colors && colors
[ -x /usr/bin/dircolors ] && eval "$(dircolors -b)"

EDITOR=vi
PAGER=less

autoload -U compinit && compinit

source "$HOME/.config/zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
source "$HOME/.config/zsh/zsh-autosuggestions/zsh-autosuggestions.zsh"
source "$HOME/.config/zsh/zsh-history-substring-search/zsh-history-substring-search.zsh"

alias ls='ls --color=auto'
alias l="ls -l"
alias ll='ls -lA'
alias grep='grep --color=auto'
alias mc='LANG=C mc'
alias vi='vim'
# Most servers does not recognize "foot" terminal
alias ssh='TERM=xterm-256color ssh'
alias uuidgen-lower="uuidgen | tr '[:upper:]' '[:lower:]'"
alias cdd="cd $HOME/Downloads"
alias cdD="cd $HOME/Google Drive/Documents"
alias cdp="cd $HOME/projects"

# get keys by running `showkey -a`
bindkey '^[[1;5D' backward-word
bindkey '^[[1;5C' forward-word
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# mixins
[ -f "$HOME/.config/zsh/.zshrc.mixins.zsh" ] && source "$HOME/.config/zsh/.zshrc.mixins.zsh"

# starship prompt
export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"
eval "$(starship init zsh)"

