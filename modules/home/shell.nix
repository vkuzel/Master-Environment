{ config, pkgs, lib, ... }:

# Replaces home/.zshenv, home/.config/zsh/* and install.sh `install_zsh_plugin`
# / `install_starship` - plugins now come from nixpkgs and are pinned by the
# flake lock instead of being downloaded from GitHub master.

let
  # The original setup keeps zsh dotfiles in ~/.config/zsh (ZDOTDIR).
  zdotDir = "${config.xdg.configHome}/zsh";

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

  # The original ~/.config/zsh/.zshrc, with Ubuntu paths replaced by store
  # paths and the few lines home-manager would otherwise generate.
  zshrc = ''
    source "${zdotDir}/.zshrc.key-bindings.zsh"
    source "${zdotDir}/.zshrc.aliases.zsh"

    # To speed-up mc's startup time we disable some advanced features
    if [ -n "$MC_SID" ]; then
        PROMPT='[%F{red}mc%f]%F{green}%n@%m%f:%F{yellow}%~%f %# '
    else
        # Completions shipped by nix profiles.
        typeset -U path cdpath fpath manpath
        for profile in ''${(z)NIX_PROFILES}; do
            fpath+=($profile/share/zsh/site-functions $profile/share/zsh/$ZSH_VERSION/functions $profile/share/zsh/vendor-completions)
        done

        # History lives in memory only, nothing is written to disk.
        HISTSIZE=50000
        SAVEHIST=0
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
in
{
  programs.zsh = {
    enable = true;
    dotDir = zdotDir;

    # Only for the nix-zsh-completions package, compinit is called by `zshrc`.
    enableCompletion = true;

    # mkForce drops every snippet home-manager would inject into .zshrc, so the
    # file is exactly `zshrc` - as the Ubuntu one was.
    initContent = lib.mkForce zshrc;
  };

  # `dockershell` sources these two files inside the container shell, so they
  # must exist as standalone files and not only inlined in .zshrc.
  xdg.configFile."zsh/.zshrc.key-bindings.zsh".text = keyBindings;
  xdg.configFile."zsh/.zshrc.aliases.zsh".text = aliases;

  programs.starship = {
    enable = true;
    # `zshrc` runs `starship init zsh` itself.
    enableZshIntegration = false;
    # The original ~/.config/starship/starship.toml, verbatim.
    settings = builtins.fromTOML (builtins.readFile ../../assets/starship.toml);
  };

  # Replaces the exports from home/.zshenv. `~/.local/bin` is on PATH via
  # home.sessionPath, the nix-daemon profile sourcing is unnecessary on NixOS.
  home.sessionVariables = {
    EDITOR = "micro";
    VISUAL = "micro";
    PAGER = "less";
  };

  home.sessionPath = [ "$HOME/.local/bin" ];

  # Replaces home/.ackrc.
  home.file.".ackrc".text = ''
    --ignore-case
    --ignore-dir=build
    --ignore-dir=out
    --ignore-dir=.idea
  '';
}
