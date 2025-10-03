# Ubuntu server post-install steps

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

