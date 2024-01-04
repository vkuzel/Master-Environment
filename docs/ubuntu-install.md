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

4. Remove some Ubuntu-Server packages

	```shell
	sudo apt purge \
		byobu \
		tilix \
		screen \
		tmux \
		cloud-guest-utils \
		cloud-initramfs-copymods \
		cloud-initramfs-dyn-netconf
	```

	Post-remove cleanup:
	```shell
	sudo apt autoremove --purge
	```


4. Install Sway & related packages

	```shell
	sudo apt install \
		xwayland \
		sway \
		swaylock \
		swayidle \
		waybar \
		wofi \
		mpd \
		brightnessctl
	```
	
	Bluetooth:
	```shell
	sudo apt install \
		bluetooth
	
	sudo systemctl enable --now bluetooth
	```
	Run `bluetoothctl`
	```
	scan on
	pair <device id>
	trust <device id>
	connect <device id>
	```

	Audio:
	```shell
	sudo apt install \
		pipewire \
		pipewire-pulse \
		pipewire-audio-client-libraries \
		libspa-0.2-bluetooth \
		libspa-0.2-jack \
		wireplumber \
		pulseaudio-utils
	```
	The `pulseaudio-utils` package for the `pactl` control command. Pipewire seems to not have native equivalent at the moment.

	Additional toos:
	```shell
	sudo apt install \
		libfuse2
	```

	Video player MPV - successor to mplayer
	```shell
	sudo apt install \
		mpv
	```
	Current version (Ubuntu 22.04) of MPV does not support PipeWire (`--ao=pipewire`), set it as a default ao as soon as it will.


	Enable services:
	```shell
	# Add the user into the video group to use brightnessctl
	sudo usermod -aG video ${USER}

	# Music Player Daemon
	sudo systemctl enable mpd
	sudo systemctl start mpd
	```

5. Install Firefox from APT

	https://ubuntuhandbook.org/index.php/2022/04/install-firefox-deb-ubuntu-22-04/#google_vignette

6. Install Thunderbird

	`sudo apt install thunderbird`

7. Install Geany GUI editor

	`apt install geany`

	Download and install "Solarized (dark)" theme: https://www.geany.org/download/themes/

8. Install and setup Google Drive

	https://github.com/astrada/google-drive-ocamlfuse#getting-started

9. Printer & scanner

	Install [CUPS](https://ubuntu.com/server/docs/service-cups)
	```shell
	sudo apt install cups
	```
	Install Brother DCP-L2532DW Linux drivers

	https://support.brother.com/g/b/downloadtop.aspx?c=eu_ot&lang=en&prod=dcpl2532dw_eu

	Install Simple scan (Document Scanner)
	```shell
	apt install simple-scan
	```

10. Skype

	```shell
	curl --location https://go.skype.com/skypeforlinux-64.deb --output skypeforlinux-64.deb
	sudo dpkg -i skypeforlinux-64.deb
	```

	When setting up Skype, switch it to floating window via _Mod+Shift+Space_ to be able to click on login button.

