{
  description = "User applications installed from nixpkgs instead of APT";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

  outputs = { nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      packages.${system}.default = pkgs.buildEnv {
        name = "master-environment";
        paths = with pkgs; [
          fastfetch
        ];
      };
    };
}
