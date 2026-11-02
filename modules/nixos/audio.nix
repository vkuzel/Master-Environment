{ ... }:

{
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;

    wireplumber.extraConfig."51-bluetooth-priority" = {
      "monitor.bluez.rules" = [
        {
          matches = [
            { "node.name" = "~bluez_output.*"; }
            { "node.name" = "~bluez_input.*"; }
          ];
          actions = {
            "update-props" = {
              "priority.session" = 3000;
            };
          };
        }
      ];
    };
  };
}
