{ ... }:

{
  networking.networkmanager.enable = true;
  networking.networkmanager.wifi.backend = "wpa_supplicant";

  # systemd-networkd would fight NetworkManager.
  networking.useNetworkd = false;
  networking.firewall.enable = true;
}
