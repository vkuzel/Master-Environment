{ lib, pkgs, ... }:

let
  jdks = {
    "17" = pkgs.jdk17;
    "21" = pkgs.jdk21;
    "25" = pkgs.jdk25;
  };
  defaultJdk = jdks."25";
in
{
  home.packages = [ defaultJdk pkgs.visualvm ];

  home.sessionVariables.JAVA_HOME = defaultJdk.home;

  home.file = lib.mapAttrs'
    (version: jdk: lib.nameValuePair ".jdks/jdk-${version}" { source = jdk.home; })
    jdks;

  xdg.desktopEntries.visualvm = {
    name = "VisualVM";
    genericName = "Java Troubleshooting Tool";
    comment = "Visual interface for viewing information about Java applications";
    exec = "${pkgs.visualvm}/bin/visualvm";
    terminal = false;
    categories = [ "Development" "Java" ];
  };
}
