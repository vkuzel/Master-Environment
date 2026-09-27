{ pkgs, ... }:

# Replaces install.sh `install_nerd_fonts` (a curl + tar + fc-cache dance) and
# home/.config/fontconfig/fonts.conf.

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
