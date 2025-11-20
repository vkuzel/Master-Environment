#!/usr/bin/env python3
import json
import re
import subprocess
import sys
import termios
import tty
from dataclasses import dataclass
from typing import Any, List, Optional, Dict


@dataclass
class BlockDevice:
    path: Optional[str]
    fstype: Optional[str]
    label: Optional[str]
    tran: Optional[str]
    mountpoint: Optional[str]
    type: Optional[str]
    size: Optional[int]
    children: Optional[List["BlockDevice"]]  # recursive definition


@dataclass
class MountableDevice:
    id: str
    name: str
    path: str
    target: str
    is_mounted: bool

    def mount(self):
        print("TODO mount ", self.name)

    def unmount(self):
        print("TODO unmount ", self.name)


def is_mountable(parent_device: BlockDevice, device: BlockDevice) -> bool:
    if not (parent_device.type == "disk" and parent_device.tran == "usb"):
        return False

    if device.type not in ['part', 'dm']:
        return False

    """Zero size disks are (probably) card readers w/o a card inserted in them"""
    if device.size == 0:
        return False

    media_mountpoint_pattern = re.compile("^/media")
    if device.mountpoint is not None and not media_mountpoint_pattern.match(device.mountpoint):
        return False

    return True


def resolve_mountable_devices(block_devices: List[BlockDevice]) -> List[MountableDevice]:
    mountable_devices: List[MountableDevice] = []
    id = 0
    for parent_device in block_devices:
        for device in parent_device.children:
            if not is_mountable(parent_device, device):
                continue

            id = id + 1
            label = f" ({device.label}) " if device.label is not None else ""

            mountable_devices.append(MountableDevice(
                id=str(id),
                name=f"{device.path}[{device.fstype}]{label}",
                path=device.path,
                target=device.mountpoint if device.mountpoint is not None else f"/media/usb{id}",
                is_mounted=bool(device.mountpoint),
            ))

    return mountable_devices


def get_block_devices() -> List[BlockDevice]:
    cmd: list[str] = [
        "lsblk", "--bytes",
        "--output", "PATH,FSTYPE,LABEL,MOUNTPOINT,TRAN,TYPE,SIZE",
        "--tree", "--json"
    ]

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
            for child in dev["children"]:
                device.children.append(parse_device(child))

        return device

    return [parse_device(d) for d in data.get("blockdevices", [])]


def read_key() -> str:
    if not sys.stdin.isatty():
        return input()

    fd = sys.stdin.fileno()
    old = termios.tcgetattr(fd)
    try:
        tty.setraw(fd)
        return sys.stdin.read(1)
    finally:
        termios.tcsetattr(fd, termios.TCSADRAIN, old)


if __name__ == "__main__":
    block_devices = get_block_devices()
    mountable_devices = resolve_mountable_devices(block_devices)

    print()
    for mountable_device in mountable_devices:
        mounted = f" \033[31m*mounted*\033[0m" if mountable_device.is_mounted else ""
        print(f"{mountable_device.id}) {mountable_device.name} -> {mountable_device.target}{mounted}")
    print()

    print("Select disk: ")
    device_id=read_key()
    print(device_id)

    for mountable_device in mountable_devices:
        if mountable_device.id == device_id:
            if mountable_device.is_mounted:
                mountable_device.mount()
            else:
                mountable_device.unmount()
