{ inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix
    ../../modules/nixos
    inputs.nixos-hardware.nixosModules.lenovo-thinkpad-t470s
  ];

  networking.hostName = "europa";

  hardware.intelgpu.computeRuntime = "legacy";

  system.stateVersion = "26.05";
}
