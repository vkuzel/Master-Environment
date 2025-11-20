#!/usr/bin/env python3
import json
import re
import subprocess
import sys
import termios
import tty
from dataclasses import dataclass
from pathlib import Path
from typing import Any, List, Optional, Dict


@dataclass
class BlockDevice:
    path: Optional[str]
    fstype: Optional[str]
    label: Optional[str]
    tran: Optional[str]
    mount_point: Optional[str]
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
class SudoRunner:
    password_manager: PasswordManager

    def run(self, cmd: List[str]) -> subprocess.CompletedProcess[str]:
        if self._is_password_needed():
            return subprocess.run(
                args=["sudo", "-S"] + cmd,
                capture_output=True,
                text=True,
                input=self.password_manager.get_password()
            )
        else:
            return subprocess.run(
                args=["sudo", "-n"] + cmd,
                capture_output=True,
                text=True,
            )

    @staticmethod
    def _is_password_needed() -> bool:
        result = subprocess.run(
            args=["sudo", "-n", "true"],
            capture_output=True,
            text=True,
        )
        return result.returncode != 0

@dataclass
class MountableDevice:
    id: str
    name: str
    path: str
    mount_point: str
    is_mounted: bool

    def mount(self, sudo_runner: SudoRunner):
        print("Mounting", self.path, "->", self.mount_point)

        target_path = Path(self.mount_point)
        if target_path.exists():
            print("Directory", self.mount_point, "already exists!")
            return

        result = sudo_runner.run(["mkdir", self.mount_point])
        if result.returncode != 0:
            print("Cannot create directory:", result.stderr)
            return

        result = sudo_runner.run(["mount", self.path, self.mount_point])
        if result.returncode != 0:
            print("Cannot mount:", result.stderr)
            return

    def unmount(self, sudo_runner: SudoRunner):
        print("Dismounting", self.path, "->", self.mount_point)

        result = sudo_runner.run(["umount", self.mount_point])
        if result.returncode != 0:
            print("Cannot dismount:", result.stderr)
            return

        result = sudo_runner.run(["rmdir", self.mount_point])
        if result.returncode != 0:
            print("Cannot remove directory:", result.stderr)
            return


def is_mountable(parent_device: BlockDevice, device: BlockDevice) -> bool:
    if not (parent_device.type == "disk" and parent_device.tran == "usb"):
        return False

    if device.type not in ['part', 'dm']:
        return False

    """Zero size disks are (probably) card readers w/o a card inserted in them"""
    if device.size == 0:
        return False

    media_mountpoint_pattern = re.compile("^/media")
    if device.mount_point is not None and not media_mountpoint_pattern.match(device.mount_point):
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
                mount_point=device.mount_point if device.mount_point is not None else f"/media/usb{device_id}",
                is_mounted=bool(device.mount_point),
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
            mount_point=dev.get("mountpoint"),
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
        mount_point="/media/usbD",
        is_mounted=False,
    ))

    print()
    for mountable_device in mountable_devices:
        mounted = f" \033[31m*mounted*\033[0m" if mountable_device.is_mounted else ""
        print(f"{mountable_device.id}) {mountable_device.name} -> {mountable_device.mount_point}{mounted}")
    print()

    device_id=read_char("Select disk:")

    for mountable_device in mountable_devices:
        if mountable_device.id == device_id:
            password_manager = PasswordManager()
            sudo_runner = SudoRunner(password_manager)
            if mountable_device.is_mounted:
                mountable_device.unmount(sudo_runner)
            else:
                mountable_device.mount(sudo_runner)


if __name__ == "__main__":
    main()