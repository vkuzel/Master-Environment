# Ubuntu server post-install steps

1. Disable _cloud-init_

	Uninstall and delete folders:

	```shell
	# Disable all services except "none"
	sudo dpkg-reconfigure cloud-init
	sudo apt purge cloud-init
	sudo apt autoremove --purge
	sudo rm -rf /etc/cloud/ && sudo rm -rf /var/lib/cloud/
	```
	
	Details: https://gist.github.com/zoilomora/f862f76335f5f53644a1b8e55fe98320

2. Replace Nvidia propiretary drivers w/ Nouveau (if present)

	At the moment Sway supports Nouveau only at the moment.
	```shell
	sudo apt purge 'nvidia*'
	sudo apt autoremove --purge
	```

	```shell
	sudo apt install nouveau-firmware
	```

3. Install Sway & related packages

	```shell
	sudo apt install \
		xwayland \
		sway \
		swaylock \
		swayidle \
		waybar \
		wofi \
		mako-notifier \
		libnotify-bin \
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

4. Install Firefox from APT

	https://ubuntuhandbook.org/index.php/2022/04/install-firefox-deb-ubuntu-22-04/#google_vignette

	Due to a bug, after installing and pinning the Mozilla's package, we have to decrease priority of Ubuntu's Firefox meta-package to prevent overriding the previous one: https://bugs.launchpad.net/ubuntu/+source/firefox/+bug/1999308

	Add following pin to the `/etc/apt/preferences.d/mozillateamppa` priority file:
	```
	Package: firefox*
	Pin: release o=Ubuntu*
	Pin-Priority: -1
	```

	Then check the package pinning via:
	```shell
	apt policy
	```

	You should see Mozilla's package pinned with priority 1001 and Ubuntu's meta-package with priority -1.

5. Install Thunderbird

	`sudo apt install thunderbird`

6. Install and setup Google Drive

	https://github.com/astrada/google-drive-ocamlfuse#getting-started

7. Printer & scanner

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

8. Skype

	```shell
	curl --location https://go.skype.com/skypeforlinux-64.deb --output skypeforlinux-64.deb
	sudo dpkg -i skypeforlinux-64.deb
	```

	When setting up Skype, switch it to floating window via _Mod+Shift+Space_ to be able to click on login button.

9. Postgresql

	```shell
	sudo apt install postgresql
	```

	Allow password-less local socket connections in `/etc/postgresql/14/main/pg_hba.conf` set method to `trust`
	```
	# TYPE  DATABASE        USER            ADDRESS                 METHOD
	local   all             all                                     trust
	```

10. Docker

	1. Install: https://docs.docker.com/engine/install/ubuntu/

	2. Post install: https://docs.docker.com/engine/install/linux-postinstall/

