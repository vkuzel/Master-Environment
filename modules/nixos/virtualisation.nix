{ ... }:

{
  virtualisation.docker = {
    enable = true;
    # TODO Consider enabling prune (it may accidentally delete / break w/ kind)
    # autoPrune.enable = true;
    # autoPrune.dates = "monthly";
    # TODO Consider `virtualisation.docker.rootless.enable = true` to avoid dockershell
  };
}
