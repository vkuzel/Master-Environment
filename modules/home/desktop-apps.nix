{ lib, pkgs, ... }:

{
  programs.firefox = {
    enable = true;
    policies = {
      DisableTelemetry = true;
      DisablePocket = true;
      PasswordManagerEnabled = false;
      OfferToSaveLogins = false;
      AutofillCreditCardEnabled = false;
      DisableFormHistory = true;
      FirefoxSuggest = {
        OnlineEnabled = false;
        Locked = true;
      };

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

  # Pin following mime types to Firefox to prevent other applications from taking over
  xdg.mimeApps =
    let
      browserMimeTypes = [
        "text/html"
        "text/xml"
        "application/xhtml+xml"
        "application/xml"
        "application/rss+xml"
        "application/rdf+xml"
        "application/pdf"
        "image/gif"
        "image/jpeg"
        "image/png"
        "image/webp"
        "x-scheme-handler/http"
        "x-scheme-handler/https"
      ];
      pinnedToFirefox = lib.genAttrs browserMimeTypes (_: [ "firefox.desktop" ]);
    in
    {
      enable = true;
      associations.added = pinnedToFirefox;
      defaultApplications = pinnedToFirefox;
    };

  programs.google-chrome = {
    enable = true;
    commandLineArgs = [ "--no-default-browser-check" ];
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

  xdg.desktopEntries.blank-box = {
    name = "Blank Box";
    exec = "${pkgs.masterEnvironmentScripts.blank-box}/bin/blank-box";
    terminal = false;
    categories = [ "Utility" ];
    settings.StartupNotify = "false";
  };

  xdg.configFile."app-launcher/apps.yaml".source = desktop-apps/apps.yaml;
}
