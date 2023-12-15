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

