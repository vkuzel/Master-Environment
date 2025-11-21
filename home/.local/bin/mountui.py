#!/usr/bin/env python3
import json
import re
import subprocess
import sys
import termios
import tty
from dataclasses import dataclass
from pathlib import Path
from typing import Any, List, Optional, Dict, Tuple


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


@dataclass
class MtpDevice:
    busLocation: int
    devNum: int
    productId: str
    vendorId: str
    product: str
    vendor: str


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
        """Check whether sudo holds password in memory"""
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
        pass

    def unmount(self, sudo_runner: SudoRunner):
        pass


@dataclass
class MountableBlockDevice(MountableDevice):
    def mount(self, sudo_runner: SudoRunner):
        print("Mounting", self.path, "->", self.mount_point)

        target_path = Path(self.mount_point)
        if target_path.exists():
            error("Directory", self.mount_point, "already exists!")
            return

        result = sudo_runner.run(["mkdir", self.mount_point])
        if result.returncode != 0:
            error("Cannot create directory:", result.stderr)
            return

        result = sudo_runner.run(["mount", self.path, self.mount_point])
        if result.returncode != 0:
            error("Cannot mount:", result.stderr)
            return

    def unmount(self, sudo_runner: SudoRunner):
        print("Dismounting", self.path, "->", self.mount_point)

        result = sudo_runner.run(["umount", self.mount_point])
        if result.returncode != 0:
            error("Cannot dismount:", result.stderr)
            return

        result = sudo_runner.run(["rmdir", self.mount_point])
        if result.returncode != 0:
            error("Cannot remove directory:", result.stderr)
            return


@dataclass
class MountableMtpDevice(MountableDevice):
    pass

class BlockDevicesFactory:
    def resolve(self) -> List[BlockDevice]:
        result = self._run_lsblk()
        if result.returncode != 0:
            error("Cannot get devices:", result.stderr)
            return []

        json_devices: Dict[str, Any] = json.loads(result.stdout)
        raw_devices = json_devices.get("blockdevices", [])
        return [self._parse_device(raw_device) for raw_device in raw_devices]

    @staticmethod
    def _run_lsblk() -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            args=["lsblk", "--bytes", "--tree", "--json", "--output", "PATH,FSTYPE,LABEL,MOUNTPOINT,TRAN,TYPE,SIZE"],
            capture_output=True,
            text=True,
        )

    def _parse_device(self, raw_device: Dict[str, Any]) -> BlockDevice:
        raw_children = raw_device.get("children", [])
        return BlockDevice(
            path=raw_device.get("path"),
            fstype=raw_device.get("fstype"),
            label=raw_device.get("label"),
            tran=raw_device.get("tran"),
            mount_point=raw_device.get("mountpoint"),
            type=raw_device.get("type"),
            size=int(raw_device["size"]) if raw_device.get("size") is not None else None,
            children=[self._parse_device(raw_device) for raw_device in raw_children],
        )


class MtpDevicesFactory:
    def resolve(self) -> List[MtpDevice]:
        result = self._run_jmtpfs()
        if result.returncode != 0:
            error("Cannot get MTP devices:", result.stderr)
            return []

        raw_device_pattern = r'^(\d+),\s*(\d+),\s*(0x[0-9a-fA-F]+),\s*(0x[0-9a-fA-F]+),\s*(.*?),\s*([^,]+)$'
        raw_devices = [match.groups() for match in re.finditer(raw_device_pattern, result.stdout, re.MULTILINE)]
        return [self._parse_device(raw_device) for raw_device in raw_devices]

    @staticmethod
    def _run_jmtpfs() -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            args=["jmtpfs", "-l"],
            capture_output=True,
            text=True,
        )

    @staticmethod
    def _parse_device(raw_device: Tuple[str, ...]) -> MtpDevice:
        return MtpDevice(
            busLocation=int(raw_device[0]),
            devNum=int(raw_device[1]),
            productId=raw_device[2].strip(),
            vendorId=raw_device[3].strip(),
            product=raw_device[4].strip(),
            vendor=raw_device[5].strip(),
        )


class MountableDevicesFactory:
    def resolve(self, block_devices: List[BlockDevice], mtp_devices: List[MtpDevice]) -> List[MountableDevice]:
        mountable_devices: List[MountableDevice] = []
        device_id = 0
        for parent_device in block_devices:
            for device in parent_device.children:
                if not self.is_mountable(parent_device, device):
                    continue

                device_id = device_id + 1
                label = f" ({device.label}) " if device.label is not None else ""

                mountable_devices.append(MountableBlockDevice(
                    id=str(device_id),
                    name=f"{device.path}[{device.fstype}]{label}",
                    path=device.path,
                    mount_point=device.mount_point if device.mount_point is not None else f"/media/usb{device_id}",
                    is_mounted=bool(device.mount_point),
                ))

        for device in mtp_devices:
            device_id = device_id + 1

            mountable_devices.append(MountableMtpDevice(
                id=str(device_id),
                name=f"{device.vendor} {device.product}",
                path="unknown",
                mount_point=f"/media/android",
                is_mounted=False,
            ))

        return mountable_devices

    @staticmethod
    def is_mountable(parent_device: BlockDevice, device: BlockDevice) -> bool:
        if not (parent_device.type == "disk" and parent_device.tran == "usb"):
            return False

        if device.type not in ['part', 'dm']:
            return False

        # Zero size disks are (probably) card readers w/o a card inserted in them
        if device.size == 0:
            return False

        media_mount_point_pattern = re.compile("^/media")
        if device.mount_point is not None and not media_mount_point_pattern.match(device.mount_point):
            return False

        return True


def error(*args):
    print("\033[31m", *args, "\033[0m", file=sys.stderr)


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
    block_devices = BlockDevicesFactory().resolve()
    mtp_devices = MtpDevicesFactory().resolve()
    mountable_devices = MountableDevicesFactory().resolve(block_devices, mtp_devices)

    # TODO Test device
    mountable_devices.append(MountableBlockDevice(
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
            break
    else:
        print("exit")


if __name__ == "__main__":
    main()