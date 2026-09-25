
export PATH=$PATH:"$HOME/.local/bin"
export ZDOTDIR="$HOME/.config/zsh"
export EDITOR=micro

# Multi-user nix installation
if [ -e "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh" ]; then
	source "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
fi

# Applications and the session environment (XDG_DATA_DIRS, XCURSOR_PATH,
# TERMINFO_DIRS, ...) are managed by home-manager, see nix/home.nix. Sourcing
# this file is required for nix desktop files and D-Bus services to be found,
# i.e., before sway.sh starts the session.
if [ -e "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh" ]; then
	source "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
fi
