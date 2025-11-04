#!/bin/bash

uid=$(id -u)
gid=$(id -g)

devices=$(lsblk --bytes --output PATH,FSTYPE,LABEL,MOUNTPOINT,TYPE,SIZE --json)
deviceIndices=$(echo $devices | jq -r '.blockdevices | to_entries | .[].key')
androidDevice=$(lsusb | grep 'MTP mode' | awk -F'ID [^ ]+ ' '{print $2}')

isMountableDrive() {
	local id=$1

	local typ=$(echo $devices | jq -r ".blockdevices[$id].type")
	if [[ "$typ" != "part" && "$typ" != "disk" ]]; then
		echo "false"
	fi


	local size=$(echo $devices | jq -r ".blockdevices[$id].size")
  # Zero size disks are (probably) card readers w/o a card attached to them
  if [[ "$size" -eq "0" ]]; then
    echo "false"
  fi

	# Disks bigger than 100G are (probably) not USB flash drives.
	if [[ "$size" -gt "100000000000" ]]; then
		echo "false"
	fi
	
	local mountpoint=$(echo $devices | jq -r ".blockdevices[$id].mountpoint")
	if [[ "$mountpoint" != "null" && ! "$mountpoint" =~ "/media" ]]; then
		echo "false"
	fi

	echo "true"
}

echo
for id in $deviceIndices; do
	if [[ "$(isMountableDrive $id)" != "true" ]]; then
		continue
	fi

	path=$(echo $devices | jq -r ".blockdevices[$id].path")
	fstype=$(echo $devices | jq -r ".blockdevices[$id].fstype")
	label=$(echo $devices | jq -r ".blockdevices[$id].label")
	mountpoint=$(echo $devices | jq -r ".blockdevices[$id].mountpoint")

	name=""
	if [[ "$label" != "null" ]]; then
		name="($label) "
	fi

	if [[ "$mountpoint" == "null" ]]; then
		target="/media/usb$id"
		echo -e "$id) $path[$fstype] $name-> $target"
	else
		echo -e "$id) $path[$fstype] $name-> $mountpoint \e[1;31m*mounted*\e[0m"
	fi
done
if [[ -n "$androidDevice" ]]; then
  target="/media/android"
  mountDetails=$(mount | grep $target)

  if [[ -z "$mountDetails" ]]; then
    echo "a) $androidDevice -> $target"
  else
    echo -e "a) $androidDevice -> $target \e[1;31m*mounted*\e[0m"
  fi
fi
echo "r) Rescan PCI devices, e.g. for SD cards"

echo
read -p "Select disk: " diskId

for id in $deviceIndices; do
	if [[ "$id" == "$diskId" ]]; then
		if [[ "$(isMountableDrive $id)" != "true" ]]; then
			continue
		fi

		path=$(echo $devices | jq -r ".blockdevices[$id].path")
		mountpoint=$(echo $devices | jq -r ".blockdevices[$id].mountpoint")
		fstype=$(echo $devices | jq -r ".blockdevices[$id].fstype")
		target="/media/usb$id"

		if [[ "$mountpoint" == "null" ]]; then
			echo "Mounting $path -> $target"
			sudo mkdir -p $target

			# ext4 does not support mounting w/ specific user
			if [[ "$fstype" != "ext4" ]]; then
				options=",uid=$uid,gid=$gid"
			fi
			sudo mount \
			--options nosuid,nodev$options \
			$path \
			$target
		else
			echo "Umounting $target"
			sudo umount $target
			sudo rm -d $target
		fi
	fi
done
if [[ "a" == "$diskId" ]]; then
  target="/media/android"
  mountDetails=$(mount | grep $target)

  if [[ -z "$mountDetails" ]]; then
    sudo mkdir -p $target
    sudo chown $UID $target
    jmtpfs $target
    echo
    echo "If you get IO error, enable MTP on you phone and try again"
  else
    fusermount -u $target
    sudo rm -d $target
  fi
fi
if [[ "r" == "$diskId" ]]; then
	echo "Rescanning PCI devices"
	echo 1 | sudo tee /sys/bus/pci/rescan
fi
