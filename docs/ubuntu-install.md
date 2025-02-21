# Ubuntu server post-install steps

1. Disable _cloud-init_

	Uninstall and delete folders:

	```shell
	# Disable all services except "none"
	sudo dpkg-reconfigure cloud-init
	sudo apt purge cloud-init
	sudo apt autoremove --purge
	sudo rm -rf /etc/cloud/ /var/lib/cloud/ /etc/netplan/*cloud-init.yaml
	```
	
	Details: https://gist.github.com/zoilomora/f862f76335f5f53644a1b8e55fe98320

2. Install correct Nvidia drivers

	There are various issues with running Sway on nvidia GPU. So far the best combinations is custom Sway build with proprietary nvidia drivers. Nouveau drivers demonstrate various issues and crashes.

	1. Sway 1.10 is not yet available through APT packages, so a custom build has to be made.

    2. nvidia 560 is tested driver version.

        Check installed version:
        ```shell
        cat /proc/driver/nvidia/version
        ```

        Install correct version if needed: https://ubuntu.com/server/docs/nvidia-drivers-installation

3. Enable (Keychron) keyboard function keys.

	```shell
	echo 0 | sudo tee /sys/module/hid_apple/parameters/fnmode
	```

4. Install Sway & related packages (for non-nvidia GPUs)

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
 		grim
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

5. Install Firefox from APT

	Add Mozilla team's PPA:
	```shell
	sudo add-apt-repository ppa:mozillateam/ppa 
	```

	Due to a bug, after installing and pinning the Mozilla's package, we have to decrease priority of Ubuntu's Firefox meta-package to prevent overriding the previous one: https://bugs.launchpad.net/ubuntu/+source/firefox/+bug/1999308

	The `/etc/apt/preferences.d/mozillateamppa` file should contain:
	```
	Package: firefox*
	Pin: release o=LP-PPA-mozillateam
	Pin-Priority: 1001
	
	Package: firefox*
	Pin: release o=Ubuntu*
	Pin-Priority: -1
	```

	Then check the package pinning via:
	```shell
	apt policy
	```
	You should see Mozilla's package pinned with priority 1001 and Ubuntu's meta-package with priority -1.

	Install Firefox:
	```shell
	sudo apt install firefox
	```

	Install ad-blocking addons:
	* AdBlocker: https://addons.mozilla.org/en-US/firefox/addon/adblock-for-youtube/
	* Unhook: https://addons.mozilla.org/en-US/firefox/addon/youtube-recommended-videos/

6. Install Thunderbird from APT

	Similar to the Firefox repository, the `/etc/apt/preferences.d/mozillateamppa` file should contain:
	```
	Package: thunderbird*
	Pin: release o=LP-PPA-mozillateam
	Pin-Priority: 1001
	
	Package: thunderbird*
	Pin: release o=Ubuntu*
	Pin-Priority: -1
	```

	Install Thunderbird:
	```shell
	sudo apt install thunderbird
 	```

7. Install and setup Google Drive

	https://github.com/astrada/google-drive-ocamlfuse#getting-started

8. Printer & scanner

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

9. Skype

	Install from Snap:
	```shell
	snap install skype
	```

	Install keyring to store the credentials:
	```shell
	sudo apt install gnome-keyring
	```

10. Docker

	1. Install: https://docs.docker.com/engine/install/ubuntu/

	2. Post install: https://docs.docker.com/engine/install/linux-postinstall/

11. Twingate VPN

	1. Install: https://www.twingate.com/docs/linux

12. WireShark
	
	```shell
	sudo apt install wireshark
	```

13. Office suite 

	```shell
	sudo apt install gimp libreoffice
	```

14. BitTorrent client

	```shell
	sudo apt install transmission-cli
	```
