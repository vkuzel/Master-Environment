{ github-copilot-cli, fetchurl }:

let
  version = "1.0.101";
  # nix store prefetch-file --json <url> | jq -r .hash
  hash = "sha256-IfdUNgu+pHFivX3otJbBanyvGZu3LImeMcC7VTNexYU=";
in

github-copilot-cli.overrideAttrs (old: {
  inherit version;

  src = fetchurl {
    inherit hash;
    url = "https://github.com/github/copilot-cli/releases/download/v${version}/github-copilot-${version}-linux-x64.tgz";
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
})
