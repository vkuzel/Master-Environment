{ user, ... }:

# The user side of the Master Environment. Everything that used to be a
# symlink created by `install.sh create_links` now lives in one of these
# modules, generated and activated by Home Manager.

{
  imports = [
    ./desktop-apps.nix
    ./editor.nix
    ./media.nix
    ./packages.nix
    ./scripts.nix
    ./shell.nix
    ./sway.nix
    ./swaync.nix
    ./terminal.nix
    ./waybar.nix
  ];

  home.username = user.name;
  home.homeDirectory = "/home/${user.name}";

  # Directories the workflow expects (sway workspaces, backup scripts, ...).
  home.file = {
    "Documents/.keep".text = "";
    "Downloads/.keep".text = "";
    "projects/.keep".text = "";
    "slop/.keep".text = "";
  };

  xdg.enable = true;

  programs.home-manager.enable = true;

  home.stateVersion = "26.05";
}
