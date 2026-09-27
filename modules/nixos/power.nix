{ ... }:

# Replaces MANUAL-POST-INSTALL steps 1.1 (logind lid switch) and 1.2 (TLP).

{
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandleLidSwitchDocked = "ignore";
    HandleLidSwitchExternalPower = "suspend";
  };

  services.tlp.enable = true;
  # power-profiles-daemon conflicts with TLP.
  services.power-profiles-daemon.enable = false;
}
