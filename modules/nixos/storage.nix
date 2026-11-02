{ pkgs, ... }:

{
  # TODO Consider rewriting mountui to use gvfs / udisk, then gvfs
  #  could be system-wide enabled, and Rhythmbox's wrapper removed
  services.dbus.packages = [ pkgs.gvfs ];
  systemd.packages = [ pkgs.gvfs ];
  services.udisks2.enable = true;

  programs.fuse.userAllowOther = true;

  boot.supportedFilesystems = [ "ntfs" "exfat" "btrfs" ];

  environment.systemPackages = with pkgs; [
    go-mtpfs
    libmtp
    veracrypt
  ];

  # mountui creates its mount points under /media.
  systemd.tmpfiles.rules = [ "d /media 0755 root root -" ];
}
