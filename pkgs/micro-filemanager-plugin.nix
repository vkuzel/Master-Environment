{ lib, stdenvNoCC, fetchFromGitHub }:

# Replaces install.sh `install_micro_plugin` (curl + unzip of a GitHub archive).
#
# NOTE: the hash below must be filled in once, on a machine with network access:
#
#   nix run nixpkgs#nix-prefetch-github -- vkuzel Micro-Filemanager-Plugin --rev main
#
# Paste the resulting `hash` here and set `enable = true` in
# modules/home/editor.nix.

stdenvNoCC.mkDerivation {
  pname = "micro-filemanager-plugin";
  version = "unstable-main";

  src = fetchFromGitHub {
    owner = "vkuzel";
    repo = "Micro-Filemanager-Plugin";
    rev = "main";
    hash = lib.fakeHash; # <- replace, see the note above
  };

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r . $out/
    runHook postInstall
  '';

  meta = {
    description = "File manager plugin for the micro editor";
    platforms = lib.platforms.all;
  };
}
