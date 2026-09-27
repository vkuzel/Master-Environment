{ inputs, user, ... }:

# Home Manager wiring, shared by every host. The user's own configuration
# lives in modules/home.

{
  home-manager = {
    # Use the system's `pkgs` (with our overlay) instead of a second instance.
    useGlobalPkgs = true;
    useUserPackages = true;
    # Never lose a stray hand-edited dotfile during activation.
    backupFileExtension = "hm-bak";
    extraSpecialArgs = { inherit inputs user; };
    users.${user.name} = import ../home;
  };
}
