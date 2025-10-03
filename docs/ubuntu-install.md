# Ubuntu server post-install steps

3. Install Sway & related packages

	```shell
	sudo apt install \
		xwayland \
		sway \
		swaylock \
		swayidle \
		waybar \
		fuzzel \
		sway-notification-center \
		libnotify-bin \
		brightnessctl \
 		playerctl \
 		desktop-file-utils \
 		grim \
 		slurp \
		chafa
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

	Additional toos:
	```shell
	sudo apt install \
		libfuse2t64
	```

	Video player MPV - successor to mplayer (mpv-mpris so that mpv can be controlled by playerctl)
	```shell
	sudo apt install \
		mpv \
 		mpv-mpris
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

4. Install and setup Google Drive

	https://github.com/astrada/google-drive-ocamlfuse#getting-started

5. Printer & scanner

	Install [CUPS](https://ubuntu.com/server/docs/service-cups)
	```shell
	sudo apt install cups
	```
	Install Brother DCP-L2532DW Linux drivers (use Driver Install Tool)

	https://support.brother.com/g/b/downloadtop.aspx?c=eu_ot&lang=en&prod=dcpl2532dw_eu

	> Input model name: DCP-L2532DW

	Install Simple scan (Document Scanner)
	```shell
	apt install simple-scan
	```

6. Docker

	1. Install: https://docs.docker.com/engine/install/ubuntu/

	2. Post install: https://docs.docker.com/engine/install/linux-postinstall/

7. Twingate VPN

	1. Install: https://www.twingate.com/docs/linux
8. WireShark
	
	```shell
	sudo apt install wireshark
	```
9. Office suite 

	```shell
	sudo apt install gimp libreoffice
	```

10. BitTorrent client

	```shell
	sudo apt install transmission-cli
	```

11. Signal

	Install: https://signal.org/download/linux/

	To prevent app window turning blank, add `--disable-gpu` into `/usr/share/applications/signal-desktop.desktop`. I.e.,
	```
	Exec=/opt/Signal/signal-desktop %U --disable-gpu
	```

12. Rhythmbox

	For connecting iPod shuffle
	```shell
	sudo apt install rhythmbox 
	```

