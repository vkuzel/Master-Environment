{ pkgs, ... }:

# Replaces the "Android file mount" apt packages and supports
# `mountui` / `backup-phone` (go-mtpfs, veracrypt, gvfs).

{
  services.gvfs.enable = true;
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
