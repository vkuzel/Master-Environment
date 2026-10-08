{ pkgs, ... }:

# System JDKs for the Java / Kotlin workflow. Only the default JDK is put on
# PATH (the others ship the same binary names); every version is symlinked into
# ~/.jdks so `java-home VERSION` and IntelliJ find it next to the JDKs IntelliJ
# downloads itself.

let
  jdks = {
    "17" = pkgs.jdk17;
    "21" = pkgs.jdk21;
    "25" = pkgs.jdk25;
  };
  defaultJdk = jdks."25";
in
{
  home.packages = [ defaultJdk ];

  home.sessionVariables.JAVA_HOME = "${defaultJdk}";

  home.file = pkgs.lib.mapAttrs'
    (version: jdk: pkgs.lib.nameValuePair ".jdks/jdk-${version}" { source = "${jdk}"; })
    jdks;
}
