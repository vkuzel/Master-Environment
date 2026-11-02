{ pkgs, ... }:

{
  fonts = {
    packages = with pkgs; [
      nerd-fonts.dejavu-sans-mono
      noto-fonts
      noto-fonts-color-emoji
    ];

    fontconfig.defaultFonts = {
      monospace = [ "DejaVuSansM Nerd Font Mono" "Noto Color Emoji" ];
      emoji = [ "Noto Color Emoji" ];
    };

    enableDefaultPackages = true;
  };
}
