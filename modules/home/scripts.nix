{ pkgs, ... }:

# Replaces install.sh `create_links` for home/.local/bin - instead of
# symlinking mutable scripts into $HOME, every script is a package with
# declared runtime dependencies (see pkgs/scripts/default.nix).
#
# Renames compared to the Ubuntu layout:
#   kill.sh                  -> kill-app   (`kill` would shadow the builtin)
#   .config/sway/lock.py     -> sway-lock
#   .config/sway/*.sh        -> sway-*

let
  scripts = pkgs.masterEnvironmentScripts;
in
{
  home.packages = with scripts; [
    backup
    backup-phone
    blank-box
    copilotw
    dirty-writeback
    dockershell
    java-home
    kill-app
    microgui
    mountui
    nmcli-device-wifi-list
    preview
    screencast-test
    start-apps
    sway-lock
    sway-rearrange-workspaces
    sway-screenshot
  ];
}
