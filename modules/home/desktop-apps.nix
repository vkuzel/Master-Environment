{ pkgs, ... }:

# Replaces the Firefox/Thunderbird PPA dance, the Signal/LibreOffice/Rhythmbox
# MANUAL-POST-INSTALL steps, and home/.local/share/applications/blank-box.desktop
# plus home/.config/app-launcher/apps.yaml.

{
  programs.firefox = {
    enable = true;
    # No Mozilla PPA and no apt pinning needed - nixpkgs ships upstream builds.
    policies = {
      DisableTelemetry = true;
      DisablePocket = true;
      ExtensionSettings = {
        # uBlock Origin
        "uBlock0@raymondhill.net" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
          installation_mode = "normal_installed";
        };
        # Unhook - Remove YouTube Recommended & Shorts
        "myallychou@gmail.com" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/youtube-recommended-videos/latest.xpi";
          installation_mode = "normal_installed";
        };
        # Startpage - Private Search Engine
        "{20fc2e06-e3e4-4b2b-812b-ab431220cada}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/startpage-private-search/latest.xpi";
          installation_mode = "normal_installed";
        };
      };
    };
  };

  programs.thunderbird = {
    enable = true;
    profiles.default.isDefault = true;
  };

  home.packages = with pkgs; [
    gimp3
    libreoffice
    rhythmbox # iPod shuffle
    signal-desktop
    simple-scan
    transmission_4
  ];

  # Signal renders a blank window with the default GPU path on sway.
  xdg.desktopEntries.signal-desktop = {
    name = "Signal";
    exec = "${pkgs.signal-desktop}/bin/signal-desktop --disable-gpu %U";
    icon = "signal-desktop";
    terminal = false;
    categories = [ "Network" "InstantMessaging" ];
    mimeType = [ "x-scheme-handler/sgnl" ];
  };

  # Replaces home/.local/share/applications/blank-box.desktop.
  xdg.desktopEntries.blank-box = {
    name = "Blank Box";
    exec = "${pkgs.masterEnvironmentScripts.blank-box}/bin/blank-box";
    terminal = false;
    categories = [ "Utility" ];
    settings.StartupNotify = "false";
  };

  # Workspace layout consumed by `start-apps`.
  xdg.configFile."app-launcher/apps.yaml".source = ../../assets/apps.yaml;
}
