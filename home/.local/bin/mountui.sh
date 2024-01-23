#!/bin/bash

uid=$(id -u)
gid=$(id -g)

devices=$(lsblk --bytes --output PATH,FSTYPE,LABEL,MOUNTPOINT,TYPE,SIZE --json)
deviceIndices=$(echo $devices | jq -r '.blockdevices | to_entries | .[].key')

for id in $deviceIndices; do
	typ=$(echo $devices | jq -r ".blockdevices[$id].type")
	if [[ "$typ" != "part" ]]; then
		continue
	fi

	# Disks bigger than 100G are (probably) not USB flash drives.
	size=$(echo $devices | jq -r ".blockdevices[$id].size")
	if [[ "$size" -gt "100000000000" ]]; then
		continue
	fi

	mountpoint=$(echo $devices | jq -r ".blockdevices[$id].mountpoint")
	if [[ "$mountpoint" != "null" && ! "$mountpoint" =~ "/media" ]]; then
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
	else
		target="$mountpoint *mounted*"
	fi

	echo "$id) $path[$fstype] $name-> $target"
done

read -p "Select disk: " diskId

for id in $deviceIndices; do
	if [[ "$id" == "$diskId" ]]; then
		typ=$(echo $devices | jq -r ".blockdevices[$id].type")
		if [[ "$typ" != "part" ]]; then
			continue
		fi

		# Disks bigger than 100G are (probably) not USB flash drives.
		size=$(echo $devices | jq -r ".blockdevices[$id].size")
		if [[ "$size" -gt "100000000000" ]]; then
			continue
		fi

		mountpoint=$(echo $devices | jq -r ".blockdevices[$id].mountpoint")
		if [[ "$mountpoint" != "null" && ! "$mountpoint" =~ "/media" ]]; then
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

