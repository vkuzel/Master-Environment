{ pkgs, user, ... }:

{
  programs.zsh.enable = true;

  security.sudo.wheelNeedsPassword = true;

  services.twingate.enable = true;

  # TODO Consider not installing Twingate on systems which don't need it.
  # The daemon exits with an error until `twingate setup` fills in network.conf,
  # and `Restart=always` turns that into a crash loop failing `nixos-rebuild`.
  systemd.services.twingate.serviceConfig.ExecCondition = pkgs.writeShellScript "twingate-configured" ''
    read -r network < /etc/twingate/network.conf || true
    [ -n "$network" ]
  '';

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
