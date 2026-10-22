{ pkgs, user, ... }:

{
  home.packages = with pkgs; [
    htop
    jq
    just
    mc

    # Utils
    ack
    bc
    p7zip
    unzip
    util-linux # uuidgen
    whois
    bubblewrap
  ];

  programs.git = {
    enable = true;
    settings = {
      user.name = user.fullName;
      user.email = user.email;
      init.defaultBranch = "main";
      pull.rebase = true;
    };
  };

  programs.bash.enable = true;
  programs.less.enable = true;
}
