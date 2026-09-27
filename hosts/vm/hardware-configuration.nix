{ lib, modulesPath, ... }:

# Static QEMU/virtio hardware - no `nixos-generate-config` needed, a libvirt
# guest always looks the same. The filesystem layout comes from
# ./disk-config.nix (disko).

{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  boot.initrd.availableKernelModules = [
    "virtio_pci"
    "virtio_blk"
    "virtio_scsi"
    "virtio_net"
    "ahci"
    "xhci_pci"
    "sd_mod"
    "sr_mod"
  ];
  boot.kernelModules = [ ];

  # virtio-gpu, used by sway through wlroots.
  hardware.graphics.enable = true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
