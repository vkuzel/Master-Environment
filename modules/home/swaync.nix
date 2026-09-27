{ ... }:

# Replaces home/.config/swaync/config.json and home/.config/swaync/style.css
# (the `sway-notification-center` apt package).

{
  services.swaync = {
    enable = true;
    settings = {
      control-center-margin-top = 12;
      control-center-margin-bottom = 128;
      control-center-margin-right = 8;
      control-center-margin-left = 8;
      keyboard-shortcuts = true;
      image-visibility = "when-available";
      hide-on-clear = true;
      hide-on-action = true;
      script-fail-notify = true;
      widgets = [ "title" "dnd" "notifications" ];
    };
    style = builtins.readFile ../../assets/swaync-style.css;
  };
}
