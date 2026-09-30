{ pkgs, ... }:

# Replaces home/.config/micro/settings.json, home/.config/micro/bindings.json
# and install.sh `install_micro_plugin`.

{
  programs.micro = {
    enable = true;
    settings = {
      basename = true;
      hlsearch = true;
      softwrap = true;
      wordwrap = true;
    };
  };

  # `tree` and `create` are commands of the Micro-Filemanager-Plugin installed
  # underneath.
  xdg.configFile."micro/bindings.json".text = builtins.toJSON {
    "Alt-/" = "lua:comment.comment";
    "CtrlUnderscore" = "lua:comment.comment";
    "Alt-1" = "command:tree";
    "Ctrl-w" = "command:quit";
    "Ctrl-Shift-PageDown" = "command:tabmove +1";
    "Ctrl-Shift-PageUp" = "command:tabmove -1";
    "OldBackspace" = "DeleteWordLeft";
    "Ctrl-Delete" = "DeleteWordRight";
    "ShiftPageUp" = "SelectPageUp";
    "ShiftPageDown" = "SelectPageDown";
    "Ctrl-Shift-End" = "SelectToEnd";
    "Ctrl-Shift-Home" = "SelectToStart";
  };

  # The Micro-Filemanager-Plugin used to be downloaded from GitHub by
  # install.sh. The directory name is the plugin id micro reports; the
  # plugin's repo.json names it `filemanager`, and its `tree` command is what
  # Alt-1 above invokes.
  xdg.configFile."micro/plug/filemanager".source =
    pkgs.micro-filemanager-plugin;

  # IntelliJ IDEA, previously installed through JetBrains Toolbox. The
  # vmoptions live in the package, see pkgs/idea.nix. Plugins and keymap are
  # still a first-run step, see MANUAL-POST-INSTALL.md.
  home.packages = [ pkgs.intellij-idea ];

  # `microgui` opens micro in a floating foot window (sway workspace 6).
  xdg.desktopEntries.microgui = {
    name = "Micro GUI";
    exec = "${pkgs.masterEnvironmentScripts.microgui}/bin/microgui %F";
    terminal = false;
    categories = [ "Utility" "TextEditor" ];
    mimeType = [ "text/plain" "text/markdown" ];
  };
}
