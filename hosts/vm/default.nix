{ lib, ... }:

# A QEMU/libvirt guest (Virtual Machine Manager), for trying the environment
# out before touching real hardware. Identical to `master` except for the
# virtual hardware and the things a VM has no use for.

{
  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix
    ../../modules/nixos
  ];

  networking.hostName = "master-vm";

  # QEMU integration: clipboard sharing, dynamic resolution, clean shutdown
  # from virt-manager.
  services.qemuGuest.enable = true;
  services.spice-vdagentd.enable = true;

  # Sway on a virtio-gpu. If the VM has no 3D acceleration, wlroots must fall
  # back to its software renderer, otherwise sway exits with
  # "failed to create renderer".
  environment.sessionVariables = {
    WLR_RENDERER = lib.mkDefault "pixman";
    WLR_NO_HARDWARE_CURSORS = "1";
  };

  # Nothing to manage in a guest.
  services.tlp.enable = lib.mkForce false;
  hardware.bluetooth.enable = lib.mkForce false;
  services.printing.enable = lib.mkForce false;
  hardware.sane.enable = lib.mkForce false;
  services.twingate.enable = lib.mkForce false;
  services.logind.settings.Login.HandleLidSwitch = lib.mkForce "ignore";

  # Handy while experimenting - reach the guest with
  #   ssh <user>@<guest-ip>
  services.openssh.enable = true;

  system.stateVersion = "26.05";
}
