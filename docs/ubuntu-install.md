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

3. Set timezone if not set correctly

	```shell
	ln -sf /usr/share/zoneinfo/Europe/Prague /etc/localtime
	```

4. Instal Nerd-Fonts (system-wide)

	```shell
	wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/DejaVuSansMono.zip
	sudo mkdir -p /usr/share/fonts/truetype/dejavu-nerd
	sudo unzip DejaVuSansMono.zip -d /usr/share/fonts/truetype/dejavu-nerd
	# Refresh font cache
	sudo fc-cache -fv
	# Verify font was installed
	fc-list
	```

5. Install Sway & related packages

	```shell
	sudo apt install \
		xwayland \
		sway \
		swaylock \
		waybar \
		wofi \
		mpd \
		brightnessctl
	```
	
	Audio:
	```shell
	sudo apt install \
		pipewire \
		pipewire-pulse \
		pipewire-audio-client-libraries \
		libspa-0.2-bluetooth \
		libspa-0.2-jack \
		wireplumber
	```


	Enable services:

	```shell
	# Add the user into the video group to use brightnessctl
	sudo usermod -aG video ${USER}

	# Music Player Daemon
	sudo systemctl enable mpd
	sudo systemctl start mpd
	```

6. Install Firefox from APT

	https://ubuntuhandbook.org/index.php/2022/04/install-firefox-deb-ubuntu-22-04/#google_vignette

