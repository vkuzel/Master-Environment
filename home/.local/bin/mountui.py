#!/usr/bin/env python3
from dataclasses import dataclass
import subprocess
import json
import re
from pprint import pprint
from typing import Any, TypedDict, List, Optional, Dict


@dataclass
class BlockDevice():
    path: Optional[str]
    fstype: Optional[str]
    label: Optional[str]
    tran: Optional[str]
    mountpoint: Optional[str]
    type: Optional[str]
    size: Optional[int]
    children: Optional[List["BlockDevice"]]  # recursive definition


@dataclass
class MountableDevice():
    id: int
    name: str
    path: str
    target: str
    is_mounted: bool


def is_mountable(block_device: BlockDevice) -> bool:
    if block_device.tran is not None or block_device.tran == "usb":
        return False

    if block_device.type not in ['part', 'disk', 'dm']:
        return False

    """Zero size disks are (probably) card readers w/o a card inserted in them"""
    if block_device.size == 0:
        return False

    media_mountpoint_pattern = re.compile("^/media")
    if block_device.mountpoint is not None and not media_mountpoint_pattern.match(block_device.mountpoint):
        return False

    return True


def resolve_mountable_devices(block_devices: List[BlockDevice]) -> List[MountableDevice]:
    mountable_devices: List[MountableDevice] = []
    id = 0
    for block_device in block_devices:
        if not is_mountable(block_device):
            continue

        id = id + 1
        label = f"({block_device.label}) " if block_device.label is not None else ""

        mountable_devices.append(MountableDevice(
            id=id,
            name=f"{block_device.path}[{block_device.fstype}] {label}",
            path=block_device.path,
            target=block_device.mountpoint if block_device.mountpoint is not None else f"/media/usb{id}",
            is_mounted=block_device.mountpoint is not None,
        ))
    return mountable_devices


def get_block_devices() -> List[BlockDevice]:
    cmd: list[str] = [
        "lsblk", "--bytes",
        "--output", "PATH,FSTYPE,LABEL,MOUNTPOINT,TRAN,TYPE,SIZE",
        "--json"
    ]

    # Run lsblk
    result: subprocess.CompletedProcess[str] = subprocess.run(
        cmd, capture_output=True, text=True, check=True
    )

    data: Dict[str, Any] = json.loads(result.stdout)

    def parse_device(dev: Dict[str, Any]) -> BlockDevice:
        device: BlockDevice = BlockDevice(
            path=dev.get("path"),
            fstype=dev.get("fstype"),
            label=dev.get("label"),
            tran=dev.get("tran"),
            mountpoint=dev.get("mountpoint"),
            type=dev.get("type"),
            size=int(dev["size"]) if dev.get("size") is not None else None,
            children=[],
        )

        if "children" in dev and isinstance(dev["children"], list):
            device["children"] = [parse_device(child) for child in dev["children"]]

        return device

    return [parse_device(d) for d in data.get("blockdevices", [])]


if __name__ == "__main__":
    block_devices = get_block_devices()
    mountable_devices = resolve_mountable_devices(block_devices)

    print()
    for mountable_device in mountable_devices:
        mounted = f" \033[31m*mounted*\033[0m" if mountable_device.is_mounted else ""
        print(f"{mountable_device.id}) {mountable_device.name} -> {mountable_device.target}{mounted}")
    print()
