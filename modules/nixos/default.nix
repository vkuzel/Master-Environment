{ ... }:

# Every system-level concern of the Master Environment. One file per topic,
# each file is a plain NixOS module - no framework, no indirection.

{
  imports = [
    ./audio.nix
    ./bluetooth.nix
    ./boot.nix
    ./desktop.nix
    ./fonts.nix
    ./home-manager.nix
    ./locale.nix
    ./networking.nix
    ./nix.nix
    ./power.nix
    ./printing.nix
    ./storage.nix
    ./users.nix
    ./virtualisation.nix
  ];
}
