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


class PasswordManager:
    def __init__(self):
        self._password: Optional[str] = None

    def get_password(self) -> str:
        if not self._password:
            self._password = self._read_password()
        return self._password

    def _read_password(self):
        if not sys.stdin.isatty():
            return input("Enter password:")

        print("Enter password: |", end="", flush=True)
        fd = sys.stdin.fileno()
        old = termios.tcgetattr(fd)
        try:
            tty.setraw(fd)
            password = ""
            for i in range(0, 1000):
                ch = sys.stdin.read(1)
                if ch in ("\n", "\r"):
                    break
                else:
                    spin=('/', '-', '\\', '|')[i % 4]
                    print(f"\b{spin}", end="", flush=True)
                    password = password + ch
            return password
        finally:
            termios.tcsetattr(fd, termios.TCSADRAIN, old)
            print()


@dataclass
class MountableDevice:
    id: str
    name: str
    path: str
    target: str
    is_mounted: bool

    def mount(self, password_manager: PasswordManager):
        print("TODO mount:", self.name, "with password:", password_manager.get_password())

    def unmount(self, password_manager: PasswordManager):
        print("TODO unmount", self.name, "with password:", password_manager.get_password())


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
    device_id = 0
    for parent_device in block_devices:
        for device in parent_device.children:
            if not is_mountable(parent_device, device):
                continue

            device_id = device_id + 1
            label = f" ({device.label}) " if device.label is not None else ""

            mountable_devices.append(MountableDevice(
                id=str(device_id),
                name=f"{device.path}[{device.fstype}]{label}",
                path=device.path,
                target=device.mountpoint if device.mountpoint is not None else f"/media/usb{device_id}",
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


def read_char(prompt: str) -> str:
    if not sys.stdin.isatty():
        return input(prompt)

    print(prompt, end=" ", flush=True)
    fd = sys.stdin.fileno()
    old = termios.tcgetattr(fd)
    ch = ""
    try:
        tty.setraw(fd)
        ch = sys.stdin.read(1)
        return ch
    finally:
        termios.tcsetattr(fd, termios.TCSADRAIN, old)
        print(ch)


def main():
    block_devices = get_block_devices()
    mountable_devices = resolve_mountable_devices(block_devices)

    mountable_devices.append(MountableDevice(
        id="d",
        name="/dev/null[dummy]",
        path="/dev/null",
        target="/dev/null",
        is_mounted=False,
    ))

    print()
    for mountable_device in mountable_devices:
        mounted = f" \033[31m*mounted*\033[0m" if mountable_device.is_mounted else ""
        print(f"{mountable_device.id}) {mountable_device.name} -> {mountable_device.target}{mounted}")
    print()

    device_id=read_char("Select disk:")

    for mountable_device in mountable_devices:
        if mountable_device.id == device_id:
            password_manager = PasswordManager()
            if mountable_device.is_mounted:
                mountable_device.unmount(password_manager)
            else:
                mountable_device.mount(password_manager)


if __name__ == "__main__":
    main()