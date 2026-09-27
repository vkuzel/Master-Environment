{ lib, pkgs, ... }:

# Replaces home/.config/sway/config, home/.config/swayidle/config,
# home/.config/swaylock/config and home/sway.sh.
#
# The keybindings and the workspace layout are expressed as Nix data, so the
# repetitive parts (10 workspaces x 2 bindings, 11 output assignments) are
# generated instead of copy-pasted.

let
  mod = "Mod4";
  alt = "Mod1";

  scripts = pkgs.masterEnvironmentScripts;

  # Every external monitor gets workspaces 1-9, the laptop panel gets 10.
  externalOutputs =
    (map (n: "DP-${toString n}") (lib.range 1 9))
    ++ [ "HDMI-A-1" "HDMI-A-2" ];
  laptopOutputs = [ "eDP-1" "eDP-2" ];

  workspaces = lib.range 1 10;

  workspaceOutputAssign =
    map
      (ws: {
        workspace = toString ws;
        output = if ws == 10 then laptopOutputs else externalOutputs;
      })
      workspaces;

  # `$mod+N` switches, `$mod+Shift+N` moves the container. Workspace 10 is
  # bound to the `0` key.
  workspaceKeybindings = lib.listToAttrs (lib.concatMap
    (ws:
      let key = if ws == 10 then "0" else toString ws; in [
        {
          name = "${mod}+${key}";
          value = "workspace number ${toString ws}";
        }
        {
          name = "${mod}+Shift+${key}";
          value = "move container to workspace number ${toString ws}";
        }
      ])
    workspaces);

  menu = "fuzzel --background=000f27ff --selection-color=eee8d5ff | xargs swaymsg exec --";
in
{
  wayland.windowManager.sway = {
    enable = true;
    # The package comes from the system-level `programs.sway.enable`, which is
    # what provides the session, the wrapper and the polkit/dbus glue.
    package = null;
    checkConfig = false;

    config = {
      modifier = mod;
      terminal = "foot";
      inherit menu;

      inherit workspaceOutputAssign;

      output."*".bg = "#018281 solid_color";

      window.border = 5;
      floating.border = 5;
      floating.modifier = mod;

      input."*" = {
        xkb_layout = "us,cz(qwerty)";
        xkb_options = "grp:alt_space_toggle";
        repeat_delay = "250";
        repeat_rate = "40";
      };

      # Waybar runs as a user systemd unit, see modules/home/waybar.nix.
      bars = [ ];

      keybindings = lib.mkOptionDefault (workspaceKeybindings // {
        "Print" = "exec ${scripts.sway-screenshot}/bin/sway-screenshot";
        "${alt}+Print" = "exec ${scripts.sway-screenshot}/bin/sway-screenshot --focused-window";

        "${mod}+Return" = "exec foot";
        "${mod}+Shift+q" = "kill";
        "${mod}+Space" = "exec ${menu}";
        "${mod}+Shift+c" = "reload";
        "${mod}+Shift+e" =
          "exec swaynag -t warning -m 'You pressed the exit shortcut. Do you really want to exit sway? This will end your Wayland session.' -B 'Yes, exit sway' 'swaymsg exit'";

        "${mod}+Left" = "focus left";
        "${mod}+Down" = "focus down";
        "${mod}+Up" = "focus up";
        "${mod}+Right" = "focus right";
        "${mod}+Shift+Left" = "move left";
        "${mod}+Shift+Down" = "move down";
        "${mod}+Shift+Up" = "move up";
        "${mod}+Shift+Right" = "move right";

        "${mod}+b" = "splith";
        "${mod}+v" = "splitv";
        "${mod}+w" = "layout tabbed";
        "${mod}+e" = "layout toggle split";

        "${mod}+Shift+r" = "exec ${scripts.sway-rearrange-workspaces}/bin/sway-rearrange-workspaces";

        "${mod}+f" = "fullscreen";
        "${mod}+Shift+space" = "floating toggle";
        "${mod}+r" = "mode resize";

        "${mod}+l" = "exec ${scripts.sway-lock}/bin/sway-lock";

        "XF86MonBrightnessUp" = "exec brightnessctl s 5%+";
        "XF86MonBrightnessDown" = "exec brightnessctl s 5%-";

        "XF86AudioRaiseVolume" = "exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+";
        "XF86AudioLowerVolume" = "exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";
        "XF86AudioMute" = "exec wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";

        "Shift+XF86AudioRaiseVolume" = "exec wpctl set-volume @DEFAULT_AUDIO_SOURCE@ 5%+";
        "Shift+XF86AudioLowerVolume" = "exec wpctl set-volume @DEFAULT_AUDIO_SOURCE@ 5%-";
        "Shift+XF86AudioMute" = "exec wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
        "XF86AudioMicMute" = "exec wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";

        "XF86AudioPause" = "exec playerctl pause";
        "XF86AudioPlay" = "exec playerctl play-pause";
        "XF86AudioStop" = "exec playerctl stop";
        "XF86AudioNext" = "exec playerctl next";
        "XF86AudioPrev" = "exec playerctl previous";
      });

      modes.resize = {
        Left = "resize shrink width 10px";
        Down = "resize grow height 10px";
        Up = "resize shrink height 10px";
        Right = "resize grow width 10px";
        Return = "mode default";
        Escape = "mode default";
      };
    };

    extraConfig = ''
      include /etc/sway/config.d/*
    '';

    # Make the user systemd units (waybar, swayidle, swaync) aware of the
    # running session.
    systemd.enable = true;
    systemd.variables = [ "--all" ];
  };

  # Replaces home/.config/swayidle/config.
  services.swayidle = {
    enable = true;
    timeouts = [
      {
        timeout = 3600;
        command = "${pkgs.masterEnvironmentScripts.sway-lock}/bin/sway-lock";
      }
    ];
    events = {
      before-sleep = "${pkgs.masterEnvironmentScripts.sway-lock}/bin/sway-lock";
    };
  };

  # Replaces home/.config/swaylock/config.
  programs.swaylock = {
    enable = true;
    settings = {
      ignore-empty-password = true;
      color = "000055";
      indicator-caps-lock = true;
      show-keyboard-layout = true;
    };
  };

  # Dark mode, replaces install.sh `configure_dark_mode` (gsettings) and
  # home/.config/gtk-3.0/settings.ini.
  gtk = {
    enable = true;
    gtk3.extraConfig.gtk-application-prefer-dark-theme = 1;
    gtk4.extraConfig.gtk-application-prefer-dark-theme = 1;
  };

  dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";

  home.sessionVariables.XDG_CURRENT_DESKTOP = "sway";
}
