{ lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix
    ../../modules/nixos
  ];

  networking.hostName = "veritas";

  # QEMU integration: clipboard sharing, dynamic resolution, ...
  services.qemuGuest.enable = true;
  services.spice-vdagentd.enable = true;

  # Sway on a virtio-gpu comp
  environment.sessionVariables = {
    WLR_RENDERER = lib.mkDefault "pixman";
    WLR_NO_HARDWARE_CURSORS = "1";
  };

  services.tlp.enable = lib.mkForce false;
  hardware.bluetooth.enable = lib.mkForce false;
  services.printing.enable = lib.mkForce false;
  hardware.sane.enable = lib.mkForce false;
  services.twingate.enable = lib.mkForce false;
  services.logind.settings.Login.HandleLidSwitch = lib.mkForce "ignore";

  services.openssh.enable = true;

  system.stateVersion = "26.05";
}
