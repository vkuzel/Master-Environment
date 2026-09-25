{
  description = "The Master Environment user applications managed by home-manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      # Flake outputs cannot take arguments, so the user the environment is
      # installed for is read from the environment. Therefore the configuration
      # has to be evaluated with the `--impure` flag, see install.sh.
      fromEnv = name:
        let value = builtins.getEnv name;
        in if value == "" then
          throw "Variable ${name} is not set, evaluate the flake with --impure"
        else
          value;
    in {
      homeConfigurations.master-environment =
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [
            ./home.nix
            {
              home.username = fromEnv "USER";
              home.homeDirectory = fromEnv "HOME";
            }
          ];
        };
    };
}
