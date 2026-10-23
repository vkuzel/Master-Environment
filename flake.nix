{
  description = "The Master Environment - Java / Kotlin dev setup with NixOS + sway";

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

    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs
    , home-manager
    , disko
    , nixos-hardware
    , ...
    }@inputs:
    let
      system = "x86_64-linux";

      user = {
        name = "vkuzel";
        fullName = "Vaclav Kuzel";
        email = "vkuzel@gmail.com";
        # TODO Generate with: mkpasswd --method=yescrypt
        initialPassword = "master";
      };

      # Only for this flake's own outputs below; the hosts get the same overlay
      # and config through `modules/nixos/nixpkgs.nix`.
      pkgs = import nixpkgs ({ inherit system; }
        // import ./pkgs/nixpkgs-config.nix nixpkgs.lib);
    in
    {
      nixosConfigurations =
        let
          mkHost = host: nixpkgs.lib.nixosSystem {
            specialArgs = { inherit inputs user; };
            modules = [
              disko.nixosModules.disko
              home-manager.nixosModules.home-manager
              host
            ];
          };
        in
        {
          europa = mkHost ./hosts/europa;
          metis = mkHost ./hosts/metis;
          veritas = mkHost ./hosts/veritas;
        };

      # TODO Put `nix fmt` into just
      formatter.${system} = pkgs.nixpkgs-fmt;

      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [ nixpkgs-fmt nil nix-tree ];
      };

      packages.${system} = {
        inherit (pkgs) master-environment-scripts;
        default = pkgs.master-environment-scripts;
      };
    };
}
