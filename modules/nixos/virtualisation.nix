{ ... }:

# Replaces MANUAL-POST-INSTALL step 3 (Docker) - `dockershell` relies on the
# `docker` group existing.

{
  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
    autoPrune.dates = "weekly";
  };
}
