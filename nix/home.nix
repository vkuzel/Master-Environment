{ pkgs, ... }:

{
  home.stateVersion = "26.05";

  # Ubuntu is not NixOS. This sets up XDG_DATA_DIRS, XCURSOR_PATH and
  # TERMINFO_DIRS so nix applications integrate with the distribution, and it
  # provides the `non-nixos-gpu-setup` command that links the nix GPU drivers
  # into /run/opengl-driver. Without it sway and other GPU accelerated
  # applications would not start, see install.sh.
  targets.genericLinux.enable = true;

  # Manage home-manager itself, so `home-manager switch` works after the first
  # activation.
  programs.home-manager.enable = true;

  # Makes fonts from home.packages visible to nix and to APT applications.
  fonts.fontconfig = {
    enable = true;
    defaultFonts = {
      monospace = [ "DejaVuSansM Nerd Font Mono" ];
      emoji = [ "Noto Color Emoji" ];
    };
  };

  home.packages = with pkgs; [
    # Fonts
    nerd-fonts.dejavu-sans-mono
    noto-fonts-color-emoji

    # Shell
    starship
    zsh-autosuggestions
    zsh-history-substring-search
    zsh-syntax-highlighting

    # Sway session
    # Sway pulls in its own Xwayland, swaybar, swaymsg and swaynag. Swaylock
    # stays on APT because it has to be setuid root to read /etc/shadow.
    sway
    swayidle
    foot
    waybar
    fuzzel
    swaynotificationcenter
    libnotify
    brightnessctl
    playerctl
    grim
    slurp
    chafa
    wl-clipboard

    # Video
    (mpv.override { scripts = [ mpvScripts.mpris ]; })

    # Office utils
    gimp
    micro

    # Utils
    _7zz
    ack
    bc
    fastfetch
    htop
    jq
    mc
    transmission_4
    unzip
    whois
  ];
}
