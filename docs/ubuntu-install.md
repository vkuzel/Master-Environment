# Ubuntu server post-install steps

1. Make interface optional in `/etc/netplan/00-installer-config.yaml`

	```yaml
	network:
	  ethernets:
	    eno2:
	      dhcp4: true
	      optional: true    # add this
	```

	This file serves as a source to generate `/etc/netplan/00-installer-config.yaml`

2. Disable _cloud-init_

	Uninstall and delete folders:

	```shell
	# Disable all services except "none"
	sudo dpkg-reconfigure cloud-init
	sudo apt purge cloud-init
	sudo apt autoremove --purge
	sudo rm -rf /etc/cloud/ && sudo rm -rf /var/lib/cloud/
	```
	
	Details: https://gist.github.com/zoilomora/f862f76335f5f53644a1b8e55fe98320

3. Instal Nerd-Fonts (system-wide)

	```shell
	wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/DejaVuSansMono.zip
	sudo mkdir -p /usr/share/fonts/truetype/dejavu-nerd
	sudo unzip DejaVuSansMono.zip -d /usr/share/fonts/truetype/dejavu-nerd
	# Refresh font cache
	sudo fc-cache -fv
	# Verify font was installed
	fc-list
	```

3. Install Sway & related packages

	```shell
	sudo apt install \
		xwayland \
		sway \
		swaylock \
		waybar \
		fonts-font-awesome \
		wofi \
		mpd \
		brightnessctl \
		pulseaudio-utils
	```

	Enable services:

	```shell
	# Add the user into the video group to use brightnessctl
	sudo usermod -aG video ${USER}

	# Music Player Daemon
	sudo systemctl enable mpd
	sudo systemctl start mpd
	```

4. Install Firefox from APT

	https://ubuntuhandbook.org/index.php/2022/04/install-firefox-deb-ubuntu-22-04/#google_vignette

