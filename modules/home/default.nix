{ config, ... }:

{
  imports = [
    ./desktop-apps.nix
    ./editor.nix
    ./java.nix
    ./media.nix
    ./packages.nix
    ./scripts.nix
    ./shell.nix
    ./sway.nix
    ./swaync.nix
    ./terminal.nix
    ./waybar.nix
  ];

  xdg = {
    enable = true;
    localBinInPath = true;

    userDirs = {
      enable = true;
      createDirectories = true;
      documents = "${config.home.homeDirectory}/Documents";
      download = "${config.home.homeDirectory}/Downloads";
      projects = "${config.home.homeDirectory}/projects";
      extraConfig.SLOP = "${config.home.homeDirectory}/slop";
      desktop = null;
      music = "${config.home.homeDirectory}/Music";
      pictures = "${config.home.homeDirectory}/Pictures";
      publicShare = null;
      templates = null;
      videos = "${config.home.homeDirectory}/Videos";
    };
  };

  home.stateVersion = "26.05";
}
