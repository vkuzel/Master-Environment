{ pkgs, ... }:

# Replaces home/.config/sway/config, home/.config/swayidle/config,
# home/.config/swaylock/config and home/sway.sh.
#
# `config.keybindings` and `config.modes` below are plain definitions, not
# `lib.mkOptionDefault`, so they replace Home Manager's default sway
# keybindings instead of being merged into them. Everything sway gets is
# therefore written out in this file.

let
  mod = "Mod4";
  alt = "Mod1";

  scripts = pkgs.masterEnvironmentScripts;

  menu = "fuzzel --background=000f27ff --selection-color=eee8d5ff | xargs swaymsg exec --";

  # Every external monitor gets workspaces 1-9, the laptop panel gets 10.
  # `swaymsg -t get_outputs` lists the names.
  externals = [
    "DP-1"
    "DP-2"
    "DP-3"
    "DP-4"
    "DP-5"
    "DP-6"
    "DP-7"
    "DP-8"
    "DP-9"
    "HDMI-A-1"
    "HDMI-A-2"
  ];
  laptop = [ "eDP-1" "eDP-2" ];
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

      workspaceOutputAssign = [
        { workspace = "1"; output = externals; }
        { workspace = "2"; output = externals; }
        { workspace = "3"; output = externals; }
        { workspace = "4"; output = externals; }
        { workspace = "5"; output = externals; }
        { workspace = "6"; output = externals; }
        { workspace = "7"; output = externals; }
        { workspace = "8"; output = externals; }
        { workspace = "9"; output = externals; }
        { workspace = "10"; output = laptop; }
      ];

      output."*".bg = "#018281 solid_color";

      # `pixel 5` borders, i.e. no titlebars.
      window = { border = 5; titlebar = false; };
      floating = { border = 5; titlebar = false; modifier = mod; };

      # Home Manager's defaults deviate from sway's own defaults here; keep
      # sway's, the original config did not override them.
      focus.wrapping = "yes";
      focus.newWindow = "urgent";

      input."*" = {
        xkb_layout = "us,cz(qwerty)";
        xkb_options = "grp:alt_space_toggle";
        repeat_delay = "250";
        repeat_rate = "40";
      };

      # Waybar runs as a user systemd unit, see modules/home/waybar.nix.
      bars = [ ];

      keybindings = {
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

        # Workspace 10 is bound to the `0` key.
        "${mod}+1" = "workspace number 1";
        "${mod}+2" = "workspace number 2";
        "${mod}+3" = "workspace number 3";
        "${mod}+4" = "workspace number 4";
        "${mod}+5" = "workspace number 5";
        "${mod}+6" = "workspace number 6";
        "${mod}+7" = "workspace number 7";
        "${mod}+8" = "workspace number 8";
        "${mod}+9" = "workspace number 9";
        "${mod}+0" = "workspace number 10";

        "${mod}+Shift+1" = "move container to workspace number 1";
        "${mod}+Shift+2" = "move container to workspace number 2";
        "${mod}+Shift+3" = "move container to workspace number 3";
        "${mod}+Shift+4" = "move container to workspace number 4";
        "${mod}+Shift+5" = "move container to workspace number 5";
        "${mod}+Shift+6" = "move container to workspace number 6";
        "${mod}+Shift+7" = "move container to workspace number 7";
        "${mod}+Shift+8" = "move container to workspace number 8";
        "${mod}+Shift+9" = "move container to workspace number 9";
        "${mod}+Shift+0" = "move container to workspace number 10";

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
      };

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
