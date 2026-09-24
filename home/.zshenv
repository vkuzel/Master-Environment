
export PATH=$PATH:"$HOME/.local/bin"
export ZDOTDIR="$HOME/.config/zsh"
export EDITOR=micro
# Snap desktop application are not added to zsh environment
export XDG_DATA_DIRS=/usr/local/share:/usr/share:/var/lib/snapd/desktop

if [ -e "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh" ]; then
	source "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
fi
