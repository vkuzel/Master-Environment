{ ... }:

{
  imports = [
    ./desktop-apps.nix
    ./editor.nix
    ./java.nix
    ./media.nix
    ./packages.nix
    ./scripts.nix
    ./shell.nix
    ./sway.nix
    ./swaync.nix
    ./terminal.nix
    ./waybar.nix
  ];

  home.file = {
    "Documents/.keep".text = "";
    "Downloads/.keep".text = "";
    "projects/.keep".text = "";
    "slop/.keep".text = "";
  };

  xdg.enable = true;
  xdg.localBinInPath = true;

  home.stateVersion = "26.05";
}
