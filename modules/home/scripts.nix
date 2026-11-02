{ pkgs, ... }:

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
    restore
    screencast-test
    start-apps
    sway-lock
    sway-rearrange-workspaces
    sway-screenshot
  ];
}
