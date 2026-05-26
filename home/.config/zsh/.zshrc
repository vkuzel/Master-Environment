EDITOR=vi
PAGER=less

source "$HOME/.config/zsh/.zshrc.key-bindings.zsh"
source "$HOME/.config/zsh/.zshrc.aliases.zsh"

# To speed-up mc's startup time we disable some advanced features
if [ -n "$MC_SID" ]; then
	PROMPT='[%F{red}mc%f]%F{green}%n@%m%f:%F{yellow}%~%f %# '
else
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
fi

