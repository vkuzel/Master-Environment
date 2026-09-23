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

      github-copilot-cli = pkgs.github-copilot-cli.overrideAttrs (old: {
        version = "1.0.89-0";
        src = pkgs.fetchurl {
          url = "https://github.com/github/copilot-cli/releases/download/v1.0.89-0/github-copilot-1.0.89-0-linux-x64.tgz";
          hash = "sha256-h8ZCuXWk27rUlroehYBvS3qywi6P7B/ySnAJvJ0HE5I=";
        };
        autoPatchelfIgnoreMissingDeps = old.autoPatchelfIgnoreMissingDeps ++ [
          "libwebkit2gtk-4.1.so.0"
          "libgtk-3.so.0"
          "libgdk-3.so.0"
          "libcairo.so.2"
          "libgdk_pixbuf-2.0.so.0"
          "libsoup-3.0.so.0"
          "libjavascriptcoregtk-4.1.so.0"
          "libwayland-client.so.0"
          "libdbus-1.so.3"
          "libxdo.so.3"
        ];
      });
    in {
      devShells.${system}.default = pkgs.mkShell {
        packages = [
          github-copilot-cli
        ];
      };
    };
}
