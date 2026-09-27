{ pkgs, ... }:

# Everything that install.sh installed through apt or `nix profile add`
# (nix/flake.nix) and that is not configured by a dedicated module.

{
  home.packages = with pkgs; [
    # Shell / CLI (previously nix/flake.nix)
    fastfetch
    htop
    jq
    mc

    # Office utils
    ack
    bc
    p7zip
    unzip
    util-linux # uuidgen
    whois
    wl-clipboard

    # Sway tooling used by keybindings and scripts
    brightnessctl
    chafa
    fuzzel
    grim
    libnotify
    slurp

    # AI
    bubblewrap
    github-copilot-cli
  ];

  programs.git = {
    enable = true;
    settings = {
      init.defaultBranch = "main";
      pull.rebase = true;
    };
  };

  programs.bash.enable = true;
  programs.less.enable = true;
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };
}
