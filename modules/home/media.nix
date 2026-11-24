{ lib, pkgs, ... }:

{
  programs.mpv = {
    enable = true;
    config = {
      volume = 75;
      ao = "pipewire";
    };
    scripts = [ pkgs.mpvScripts.mpris ];
  };

  services.mpris-proxy.enable = true;

  systemd.user.services.mpris-proxy.Install.WantedBy =
    lib.mkForce [ "graphical-session.target" ];
}
