{ config, lib, pkgs, ... }:

let
  ini = "${config.xdg.configHome}/mc/ini";

  setOption = section: key: value:
    "${pkgs.crudini}/bin/crudini --set ${ini} ${section} ${key} ${value}";
in
{
  home.packages = [ pkgs.mc ];

  home.activation.midnightCommanderSettings =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD mkdir -p ${config.xdg.configHome}/mc
      $DRY_RUN_CMD ${setOption "Midnight-Commander" "skin" "gotar"}
      # Use $EDITOR instead of the built-in mcedit
      $DRY_RUN_CMD ${setOption "Midnight-Commander" "use_internal_edit" "false"}
    '';
}
