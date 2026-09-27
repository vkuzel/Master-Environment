{ ... }:

# Replaces install.sh `configure_network_manager` plus the cloud-init purge -
# NixOS never installs either.

{
  networking.networkmanager.enable = true;
  networking.networkmanager.wifi.backend = "wpa_supplicant";

  # systemd-networkd would fight NetworkManager.
  networking.useNetworkd = false;
  networking.firewall.enable = true;
}
