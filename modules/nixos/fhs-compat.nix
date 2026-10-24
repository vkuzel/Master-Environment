{ pkgs, ... }:

{
  # TODO /bin/bash hotfix, remove as soon as all script are migrated to /usr/bin/env bash
  systemd.tmpfiles.rules = [
    "L+ /bin/bash - - - - ${pkgs.bash}/bin/bash"
  ];
}
