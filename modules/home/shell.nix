{ config, pkgs, lib, ... }:

# Replaces home/.zshenv, home/.config/zsh/* and install.sh `install_zsh_plugin`
# / `install_starship` - plugins now come from nixpkgs and are pinned by the
# flake lock instead of being downloaded from GitHub master. The dotfiles are
# written by hand, home-manager's `programs.zsh` module would add blocks of its
# own (HISTFILE, HELPDIR, setopt, ...) to .zshrc.

let
  # The original setup keeps zsh dotfiles in ~/.config/zsh (ZDOTDIR).
  zdotDir = "${config.xdg.configHome}/zsh";

  zshenv = ''
    export ZDOTDIR="${zdotDir}"
    source "${config.home.sessionVariablesPackage}/etc/profile.d/hm-session-vars.sh"
  '';

  zshrc = ''
    source "${zdotDir}/.zshrc.key-bindings.zsh"
    source "${zdotDir}/.zshrc.aliases.zsh"

    unset HISTFILE
    SAVEHIST=0

    # To speed-up mc's startup time we disable some advanced features
    if [ -n "$MC_SID" ]; then
        PROMPT='[%F{red}mc%f]%F{green}%n@%m%f:%F{yellow}%~%f %# '
    else
        HISTSIZE=50000
        setopt HIST_IGNORE_DUPS

        autoload -U colors && colors
        eval "$(${pkgs.coreutils}/bin/dircolors -b)"

        autoload -U compinit && compinit

        source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
        source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh
        source ${pkgs.zsh-history-substring-search}/share/zsh-history-substring-search/zsh-history-substring-search.zsh
        # mixins
        [ -f "${zdotDir}/.zshrc.mixins.zsh" ] && source "${zdotDir}/.zshrc.mixins.zsh"

        # starship prompt, STARSHIP_CONFIG is exported from .zshenv
        if [[ $TERM != "dumb" ]]; then
            eval "$(${lib.getExe pkgs.starship} init zsh)"
        fi
    fi
  '';

  keyBindings = ''
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
  '';

  aliases = ''
    alias cl='clear'
    alias ls='ls --color=auto'
    alias l="ls -l"
    alias ll='ls -lA'
    alias grep='grep --color=auto'
    alias vi='micro'
    alias mi='micro'
    alias bc='bc -l'
    # Most servers do not recognize "foot" terminal
    alias ssh='TERM=xterm-256color ssh'
    alias uuidgen-lower="uuidgen | tr '[:upper:]' '[:lower:]'"
    alias cdd="cd $HOME/Downloads"
    alias cdD="cd $HOME/Documents"
    alias cdp="cd $HOME/projects"
    alias cds="cd $HOME/slop"
  '';

  ackrc = ''
    --ignore-case
    --ignore-dir=build
    --ignore-dir=out
    --ignore-dir=.idea
  '';
in
{
  home.sessionVariables = {
    EDITOR = "micro";
    VISUAL = "micro";
    PAGER = "less";
  };

  home.sessionPath = [ "$HOME/.local/bin" ];

  home.file.".zshenv".text = zshenv;

  # TODO zoxide + fzf
  xdg.configFile."zsh/.zshrc".text = zshrc;
  xdg.configFile."zsh/.zshrc.key-bindings.zsh".text = keyBindings;
  xdg.configFile."zsh/.zshrc.aliases.zsh".text = aliases;

  programs.starship = {
    enable = true;
    enableZshIntegration = false; # Enabled manually in zshrc
    settings = builtins.fromTOML (builtins.readFile shell/starship.toml);
  };

  home.file.".ackrc".text = ackrc;
}
