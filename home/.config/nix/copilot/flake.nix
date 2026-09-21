{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

  outputs = { nixpkgs, ... }:
    let
      system = "x86_64-linux";

      pkgs = import nixpkgs {
        inherit system;

        config.allowUnfreePredicate = pkg:
          builtins.elem (nixpkgs.lib.getName pkg) [
            "github-copilot-cli"
          ];
      };
    in {
      devShells.${system}.default = pkgs.mkShell {
        packages = [
          pkgs.github-copilot-cli
        ];
      };
    };
}
