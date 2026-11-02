{ inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix
    ../../modules/nixos
    inputs.nixos-hardware.nixosModules.lenovo-thinkpad-t14s
    inputs.nixos-hardware.nixosModules.common-cpu-intel
  ];

  networking.hostName = "metis";

  hardware.intelgpu.computeRuntime = "legacy";

  system.stateVersion = "26.05";
}
