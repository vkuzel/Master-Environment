{ pkgs, ... }:

{
  programs.waybar = {
    enable = true;
    systemd.enable = true;

    settings.mainBar = import waybar/waybar-settings.nix;
    style = builtins.readFile waybar/waybar-style.css;
  };

  home.packages = with pkgs; [
    pavucontrol
    playerctl
  ];
}
