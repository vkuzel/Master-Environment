{
  description = "The Master Environment - a declarative NixOS port of the Ubuntu setup";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
  };

  outputs =
    { self
    , nixpkgs
    , home-manager
    , disko
    , nixos-hardware
    ,
    }@inputs:
    let
      system = "x86_64-linux";

      # Single place where the identity of the machine's owner is defined.
      # Every module reads it from `specialArgs`, nothing is hard-coded.
      user = {
        name = "vkuzel";
        fullName = "Vaclav Kuzel";
        # Generate with: mkpasswd --method=yescrypt
        initialPassword = "master";
      };

      pkgs = import nixpkgs {
        inherit system;
        overlays = [ (import ./pkgs) ];
        config.allowUnfreePredicate =
          pkg: builtins.elem (nixpkgs.lib.getName pkg) [
            "github-copilot-cli"
            "idea"
            "signal-desktop"
            "twingate"
            "veracrypt"
          ];
      };
    in
    {
      nixosConfigurations =
        let
          mkHost = host: nixpkgs.lib.nixosSystem {
            inherit pkgs system;
            specialArgs = { inherit inputs user; };
            modules = [
              disko.nixosModules.disko
              home-manager.nixosModules.home-manager
              host
            ];
          };
        in
        {
          # The physical laptop.
          master = mkHost ./hosts/master;
          # A QEMU/libvirt guest, see INSTALL-VM.md.
          vm = mkHost ./hosts/vm;
        };

      # `nix fmt`
      formatter.${system} = pkgs.nixpkgs-fmt;

      # `nix develop` - tooling for working on this repository itself.
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [ nixpkgs-fmt nil nix-tree ];
      };

      # `nix build .#master-environment-scripts` - all helper scripts.
      packages.${system} = {
        inherit (pkgs) master-environment-scripts;
        default = pkgs.master-environment-scripts;
      };
    };
}
