{ pkgs, ... }:

{
  home.packages = [ pkgs.intellij-idea ];

  programs.micro = {
    enable = true;
    settings = {
      basename = true;
      hlsearch = true;
      softwrap = true;
      wordwrap = true;
    };
  };

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

  xdg.configFile."micro/plug/filemanager".source =
    pkgs.micro-filemanager-plugin;

  xdg.desktopEntries.microgui = {
    name = "Micro GUI";
    exec = "${pkgs.masterEnvironmentScripts.microgui}/bin/microgui %F";
    terminal = false;
    categories = [ "Utility" "TextEditor" ];
    mimeType = [ "text/plain" "text/markdown" ];
  };
}
