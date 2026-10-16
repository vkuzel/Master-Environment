{ config, lib, modulesPath, ... }:

# Placeholder. Replace with the file generated on the target machine by
#   sudo nixos-generate-config --no-filesystems --show-hardware-config
# The filesystem layout itself is declared in ./disk-config.nix (disko).

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "thunderbolt" "nvme" "usb_storage" "sd_mod" ];
  boot.kernelModules = [ "kvm-intel" ];

  # Intel / AMD GPU only - sway is unreliable on NVIDIA, see README.
  hardware.graphics.enable = true;
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
