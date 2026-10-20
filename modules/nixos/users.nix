{ pkgs, user, ... }:

{
  programs.zsh.enable = true;

  security.sudo.wheelNeedsPassword = true;

  services.twingate.enable = true;

  # TODO Consider storing secrets in `hashedPasswordFile` backed by sops-nix / agenix.
  users.mutableUsers = true;

  users.users.${user.name} = {
    isNormalUser = true;
    description = user.fullName;
    shell = pkgs.zsh;
    initialPassword = user.initialPassword;
    extraGroups = [
      "wheel" # sudo
      "video" # brightnessctl
      "audio"
      "input"
      "networkmanager"
      "scanner"
      "lp"
    ];
  };
}
