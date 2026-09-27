{ lib, pkgs, user, ... }:

# Replaces the whole "Sway" + "screen sharing" section of install.sh, plus
# `home/sway.sh` (the dbus-run-session wrapper is no longer needed - greetd
# starts the session inside a proper D-Bus/systemd user session).

{
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
    # Everything the sway config and the helper scripts shell out to.
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

  # brightnessctl needs the udev rules plus membership in the `video` group,
  # see modules/nixos/users.nix.
  services.udev.packages = [ pkgs.brightnessctl ];

  # Screen sharing (MS Teams / Meet in the browser).
  # Test: https://mozilla.github.io/webrtc-landing/gum_test.html
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    # File picker dialogs for GTK apps (e.g. Outlook in Chrome).
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.sway = {
      default = lib.mkForce [ "wlr" "gtk" ];
      "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
    };
  };

  # Minimal greeter instead of a full display manager.
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd sway";
        user = "greeter";
      };
    };
  };

  security.polkit.enable = true;
  services.gnome.gnome-keyring.enable = true;
  programs.dconf.enable = true;

  # `swaylock` must be able to verify the password.
  security.pam.services.swaylock = { };

  # Dark mode everywhere, replaces install.sh `configure_dark_mode`.
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    XDG_CURRENT_DESKTOP = "sway";
  };

  # The AppArmor bubblewrap profile from system/bwrap-userns-restrict is an
  # Ubuntu-specific workaround for its unprivileged-userns restriction.
  # NixOS does not restrict user namespaces, so `copilotw` sandboxing works
  # out of the box and the profile is intentionally not ported.
  security.unprivilegedUsernsClone = true;

  # Keep the session alive for the user's systemd services (waybar, swayidle).
  services.logind.settings.Login.KillUserProcesses = false;
  users.users.${user.name}.linger = true;
}
