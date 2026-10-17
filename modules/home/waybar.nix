{ pkgs, ... }:

# Replaces home/.config/waybar/config and home/.config/waybar/style.css.
# The bar is a user systemd unit bound to the sway session instead of being
# spawned by `bar { swaybar_command waybar }`.

{
  programs.waybar = {
    enable = true;
    # Bound to graphical-session.target, which sway activates via
    # wayland.windowManager.sway.systemd.enable.
    systemd.enable = true;

    # Generated from the original JSONC config, see waybar/waybar-settings.nix.
    settings.mainBar = import waybar/waybar-settings.nix;

    style = builtins.readFile waybar/waybar-style.css;
  };

  # Modules referenced by the bar.
  home.packages = with pkgs; [
    pavucontrol
    playerctl
  ];
}
