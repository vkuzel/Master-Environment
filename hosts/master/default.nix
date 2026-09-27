{ ... }:

# The physical laptop: an Intel/AMD ThinkPad with one or two 27" displays.

{
  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix
    ../../modules/nixos
  ];

  networking.hostName = "master";

  # Optional: pull in the profile matching your machine, see
  # https://github.com/NixOS/nixos-hardware#modules - e.g.
  #   inputs.nixos-hardware.nixosModules.lenovo-thinkpad-t14-amd-gen4
  # Left out of the import list so a fresh machine evaluates without
  # accidentally picking the wrong profile.

  # Never changed after the first install, see
  # https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion
  system.stateVersion = "26.05";
}
