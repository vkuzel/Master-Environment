{ ... }:

# Replaces `install_apt_package bluetooth` + `enable_systemctl_service bluetooth`.

{
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings.General.Experimental = true; # battery level reporting
  };
}
