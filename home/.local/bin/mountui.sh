#!/bin/bash

uid=$(id -u)
gid=$(id -g)

devices=$(lsblk --bytes --output PATH,FSTYPE,LABEL,MOUNTPOINT,TYPE,SIZE --json)
deviceIndices=$(echo $devices | jq -r '.blockdevices | to_entries | .[].key')

isMountableDrive() {
	local id=$1

	local typ=$(echo $devices | jq -r ".blockdevices[$id].type")
	if [[ "$typ" != "part" ]]; then
		echo "false"
	fi


	# Disks bigger than 100G are (probably) not USB flash drives.
	local size=$(echo $devices | jq -r ".blockdevices[$id].size")
	if [[ "$size" -gt "100000000000" ]]; then
		echo "false"
	fi
	
	local mountpoint=$(echo $devices | jq -r ".blockdevices[$id].mountpoint")
	if [[ "$mountpoint" != "null" && ! "$mountpoint" =~ "/media" ]]; then
		echo "false"
	fi

	echo "true"
}

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

read -p "Select disk: " diskId

for id in $deviceIndices; do
	if [[ "$id" == "$diskId" ]]; then
		if [[ "$(isMountableDrive $id)" != "true" ]]; then
			continue
		fi

		path=$(echo $devices | jq -r ".blockdevices[$id].path")
		target="/media/usb$id"

		if [[ "$mountpoint" == "null" ]]; then
			echo "Mounting $path -> $target"
			sudo mkdir -p $target
			sudo mount \
				--options nosuid,nodev \
				$path \
				$target
		else
			echo "Umounting $target"
			sudo umount $target
			sudo rm -d $target
		fi
	fi
done

