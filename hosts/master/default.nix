{ inputs, user, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix
    ../../modules/nixos
  ];

  networking.hostName = "master";

  # The laptop this environment targets. Replace with the profile matching your
  # hardware, see https://github.com/NixOS/nixos-hardware#modules
  # e.g. inputs.nixos-hardware.nixosModules.lenovo-thinkpad-t14-amd-gen4
  # imports above; kept out of the default import list so a fresh machine
  # evaluates without picking a wrong profile.
  _module.args.nixosHardware = inputs.nixos-hardware;

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "hm-bak";
    extraSpecialArgs = { inherit inputs user; };
    users.${user.name} = import ../../modules/home;
  };

  # Never changed after the first install, see
  # https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion
  system.stateVersion = "26.05";
}
