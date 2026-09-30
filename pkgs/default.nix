final: prev:

# A single overlay carrying everything that is not in nixpkgs as-is.
# Applied in flake.nix, so `pkgs.<name>` works in every module.

{
  # All helper scripts from home/.local/bin, packaged with real dependencies.
  masterEnvironmentScripts = final.callPackage ./scripts { };

  master-environment-scripts = final.masterEnvironmentScripts.all;

  # Pinned Copilot CLI, ported 1:1 from home/.config/nix/copilot/flake.nix.
  github-copilot-cli = prev.github-copilot-cli.overrideAttrs (old: {
    version = "1.0.89-0";
    src = prev.fetchurl {
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

  micro-filemanager-plugin = prev.callPackage ./micro-filemanager-plugin.nix { };

  # IntelliJ IDEA with the vmoptions and Wayland flag this environment needs.
  intellij-idea = final.callPackage ./idea.nix { };
}
