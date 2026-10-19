{ lib, pkgs, user, ... }:

{
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;

    extraPackages = with pkgs; [
      brightnessctl
      chafa
      desktop-file-utils
      foot
      fuzzel
      grim
      jq
      libnotify
      playerctl
      slurp
      swayidle
      swaylock
      swaynotificationcenter
      wl-clipboard
      xwayland
    ];
  };

  services.udev.packages = [ pkgs.brightnessctl ];

  # Screen sharing test: https://mozilla.github.io/webrtc-landing/gum_test.html
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.sway = {
      default = lib.mkForce [ "wlr" "gtk" ];
      "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
    };

    wlr = {
      enable = true;

      settings.screencast = {
        chooser_type = "dmenu";
        chooser_cmd = "${pkgs.masterEnvironmentScripts.sway-share-picker}/bin/sway-share-picker";
      };
    };
  };

  services.greetd = {
    enable = true;
    useTextGreeter = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --asterisks --background matrix --cmd sway";
        user = "greeter";
      };
    };
  };

  security.polkit.enable = true;
  services.gnome.gnome-keyring.enable = true;
  programs.dconf.enable = true;

  security.pam.services.swaylock = { };

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    XDG_CURRENT_DESKTOP = "sway";
  };

  security.unprivilegedUsernsClone = true;

  services.logind.settings.Login.KillUserProcesses = false;
  users.users.${user.name}.linger = true;
}
