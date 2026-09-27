{ pkgs, ... }:

# Replaces MANUAL-POST-INSTALL step 2 (CUPS + Brother DCP-L2532DW + scanner).

{
  services.printing = {
    enable = true;
    # brlaser drives the Brother DCP-L2532DW without the vendor blob.
    drivers = with pkgs; [ brlaser gutenprint ];
  };

  # Network printer/scanner discovery.
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  hardware.sane.enable = true;
}
