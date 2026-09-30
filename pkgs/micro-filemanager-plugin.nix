{ lib, stdenvNoCC, fetchFromGitHub }:

# Replaces install.sh `install_micro_plugin` (curl + unzip of a GitHub archive).
#
# Installed by modules/home/editor.nix into ~/.config/micro/plug/filemanager,
# which is what provides micro's `tree` command (bound to Alt-1).

stdenvNoCC.mkDerivation {
  pname = "micro-filemanager-plugin";
  version = "0-unstable-2026-08-11";

  src = fetchFromGitHub {
    owner = "vkuzel";
    repo = "Micro-Filemanager-Plugin";
    rev = "e0e57048b0d90598741eb9315551655d0566aa60";
    hash = "sha256-UPZl61JK4F78SEO+yS/+vhmRFiKu+zgneOW+x0G/Rzc=";
  };

  # micro reads the plugin directory directly: every *.lua file is a source,
  # repo.json provides the plugin name and syntax.yaml is pulled in at runtime
  # by config.AddRuntimeFile.
  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp filemanager.lua repo.json syntax.yaml $out/
    runHook postInstall
  '';

  meta = {
    description = "File manager plugin for the micro editor";
    homepage = "https://github.com/vkuzel/Micro-Filemanager-Plugin";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
