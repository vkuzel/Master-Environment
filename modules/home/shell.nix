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

  aliases = {
    ls = "ls --color=auto";
    l = "ls -l";
    ll = "ls -lA";
    grep = "grep --color=auto";
    vi = "micro";
    mi = "micro";
    bc = "bc -l";
    # Most servers do not recognize the "foot" terminal
    ssh = "TERM=xterm-256color ssh";
    uuidgen-lower = "uuidgen | tr '[:upper:]' '[:lower:]'";
    cdd = "cd $HOME/Downloads";
    cdD = "cd $HOME/Documents";
    cdp = "cd $HOME/projects";
    cds = "cd $HOME/slop";
  };
in
{
  programs.zsh = {
    enable = true;
    dotDir = zdotDir;

    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    historySubstringSearch.enable = true;
    enableCompletion = true;

    shellAliases = aliases;

    history = {
      size = 50000;
      save = 50000;
      path = "${config.xdg.stateHome}/zsh/history";
      ignoreDups = true;
      share = true;
    };

    initContent = lib.mkMerge [
      (lib.mkOrder 550 ''
        autoload -U colors && colors
        eval "$(${pkgs.coreutils}/bin/dircolors -b)"
      '')
      (lib.mkOrder 1000 ''
        source "${zdotDir}/.zshrc.key-bindings.zsh"

        # mixins - machine local, never committed
        [ -f "${zdotDir}/.zshrc.mixins.zsh" ] && source "${zdotDir}/.zshrc.mixins.zsh"

        # Midnight Commander subshell: keep the prompt cheap.
        if [ -n "$MC_SID" ]; then
          PROMPT='[%F{red}mc%f]%F{green}%n@%m%f:%F{yellow}%~%f %# '
        fi
      '')
    ];
  };

  # `dockershell` sources these two files inside the container shell, so they
  # must exist as standalone files and not only inlined in .zshrc.
  xdg.configFile."zsh/.zshrc.key-bindings.zsh".text = keyBindings;
  xdg.configFile."zsh/.zshrc.aliases.zsh".text =
    lib.concatStringsSep "\n"
      (lib.mapAttrsToList (name: value: "alias ${name}=${lib.escapeShellArg value}") aliases);

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
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

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };
}
