{ pkgs, ... }:

{
  programs.firefox = {
    enable = true;
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

  # TODO Consider removing.
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "application/xhtml+xml" = [ "firefox.desktop" ];
      "application/x-extension-htm" = [ "firefox.desktop" ];
      "application/x-extension-html" = [ "firefox.desktop" ];
      "application/x-extension-shtml" = [ "firefox.desktop" ];
      "application/x-extension-xht" = [ "firefox.desktop" ];
      "application/x-extension-xhtml" = [ "firefox.desktop" ];
      "text/html" = [ "firefox.desktop" ];
      "x-scheme-handler/ftp" = [ "firefox.desktop" ];
      "x-scheme-handler/http" = [ "firefox.desktop" ];
      "x-scheme-handler/https" = [ "firefox.desktop" ];
    };
  };

  programs.thunderbird = {
    enable = true;
    profiles.default.isDefault = true;
  };

  home.packages = with pkgs; [
    google-chrome
    gimp3
    libreoffice
    rhythmbox # iPod shuffle
    signal-desktop
    simple-scan
    transmission_4
  ];

  xdg.desktopEntries.blank-box = {
    name = "Blank Box";
    exec = "${pkgs.masterEnvironmentScripts.blank-box}/bin/blank-box";
    terminal = false;
    categories = [ "Utility" ];
    settings.StartupNotify = "false";
  };

  xdg.configFile."app-launcher/apps.yaml".source = desktop-apps/apps.yaml;
}
