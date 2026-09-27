{ pkgs, user, ... }:

# Replaces install.sh `add_current_user_into_group`, `chsh_zsh` and the
# Docker/Twingate post-install steps.

{
  # Keep passwords mutable so the bootstrap `initialPassword` below can be
  # replaced with `passwd`. Set to false once secrets move to
  # `hashedPasswordFile` (sops-nix / agenix).
  users.mutableUsers = true;

  users.users.${user.name} = {
    isNormalUser = true;
    description = user.fullName;
    shell = pkgs.zsh;
    # Change immediately after the first boot with `passwd`, or switch to
    # `hashedPasswordFile` backed by sops-nix / agenix.
    initialPassword = user.initialPassword;
    extraGroups = [
      "wheel" # sudo
      "video" # brightnessctl
      "audio"
      "input"
      "networkmanager"
      "docker" # dockershell
      "scanner"
      "lp"
    ];
  };

  # The login shell must be enabled system-wide, the user-level configuration
  # lives in modules/home/shell.nix.
  programs.zsh.enable = true;

  security.sudo.wheelNeedsPassword = true;

  # MANUAL-POST-INSTALL step 4 - Twingate VPN.
  services.twingate.enable = true;
}
