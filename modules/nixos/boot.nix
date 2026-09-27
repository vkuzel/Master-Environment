{ ... }:

{
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = true;

  # `dirty-writeback.sh` watches these; the Ubuntu setup tuned nothing, keep
  # kernel defaults but make the knob discoverable.
  boot.kernel.sysctl = { };
}
