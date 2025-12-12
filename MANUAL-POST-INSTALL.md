# Ubuntu server post-install steps

1. Suspend on lid close

	1. Configure `/etc/systemd/logind.conf`
		```
		HandleLidSwitch=suspend
		HandleLidSwitchDocked=ignore
		HandleLidSwitchExternalPower=suspend
		```

		And reload logind
		```shell
		sudo systemctl restart systemd-logind
		```

		Verify logind registers lid-close event
		```shell
		sudo journalctl -u systemd-logind -f
		``` 

	2. Automated power optimizer TLP

		```shell
		apt install tlp
		systemctl enable tlp --now
		```

2. Printer & scanner

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

3. Docker

	1. Install: https://docs.docker.com/engine/install/ubuntu/

	2. Post install: https://docs.docker.com/engine/install/linux-postinstall/

4. Twingate VPN

	1. Install: https://www.twingate.com/docs/linux

5. Signal

	Install: https://signal.org/download/linux/

	To prevent app window turning blank, add `--disable-gpu` into `/usr/share/applications/signal-desktop.desktop`. I.e.,
	```
	Exec=/opt/Signal/signal-desktop %U --disable-gpu
	```

6. LibreOffice

	```shell
	sudo apt install libreoffice
	```

7. Rhythmbox

	For connecting iPod shuffle
	```shell
	sudo apt install rhythmbox 
	```

8. IntelliJ IDEA setup:

    Shortcuts:
    * Select Next Tab: Ctrl + Page Down
    * Select Previous Tab: Ctrl + Page Up
    * Close Tab: Ctrl + W

    Settings:
    * Disable: Settings -> Editor -> General -> Smart Keys -> Markdown -> Adjust indentation on type

9. Firefox focus extensions

    * Startpage - Private Search Engine
    * uBlock Origin
    * Unhook - Remove YouTube Recommended & Shorts
