{ pkgs, ... }:

# Replaces home/.config/mpv/mpv.conf plus the mpv / mpv-mpris apt packages.

{
  programs.mpv = {
    enable = true;
    config = {
      volume = 75;
      # Unlike Ubuntu 22.04, the nixpkgs build does support PipeWire.
      ao = "pipewire";
    };
    # mpv-mpris, so waybar/playerctl can control playback.
    scripts = [ pkgs.mpvScripts.mpris ];
  };

  services.mpris-proxy.enable = true;
}
