#!/usr/bin/env python3
import getpass
import json
import os
import re
import hashlib
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
    id: str
    name: str


class SudoRunner:
    def __init__(self):
        self._password: Optional[str] = None

    def run(self, cmd: List[str]) -> subprocess.CompletedProcess[str]:
        if self._is_password_needed():
            return subprocess.run(
                args=["sudo", "-S"] + cmd,
                capture_output=True,
                text=True,
                input=self._get_password()
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

    def _get_password(self) -> str:
        if not self._password:
            user = getpass.getuser()
            self._password = password_prompt(f"[sudo] password for {user}:")
        return self._password


@dataclass
class MountableDevice:
    name: str
    mount_point: str

    def is_mounted(self) -> bool:
        pass

    def mount(self, sudo_runner: SudoRunner):
        pass

    def unmount(self, sudo_runner: SudoRunner):
        pass

    def _setup_mount_point(self, sudo_runner: SudoRunner) -> bool:
        target_path = Path(self.mount_point)
        if target_path.exists():
            error("Directory", self.mount_point, "already exists!")
            return False

        result = sudo_runner.run(["mkdir", self.mount_point])
        if result.returncode != 0:
            error("Cannot create directory:", result.stderr)
            return False

        uid = os.getuid()
        result = sudo_runner.run(["chown", f"{uid}", self.mount_point])
        if result.returncode != 0:
            error("Cannot mount:", result.stderr)
            return False

        return True

    def _cleanup_mount_point(self, sudo_runner: SudoRunner) -> bool:
        result = sudo_runner.run(["rmdir", self.mount_point])
        if result.returncode != 0:
            error("Cannot remove directory:", result.stderr)
            return False

        return True


@dataclass
class MountableBlockDevice(MountableDevice):
    fstype: str
    path: str
    mounted: bool

    def is_mounted(self) -> bool:
        return self.mounted

    def mount(self, sudo_runner: SudoRunner):
        print("Mounting", self.path, "->", self.mount_point)

        if not self._setup_mount_point(sudo_runner):
            return

        options = ["nosuid", "nodev"]
        # ext4 does not support mounting w/ specific user
        if self.fstype != "ext4":
            uid = os.getuid()
            options.append(f"uid={uid}")
            gid = os.getgid()
            options.append(f"gid={gid}")

        result = sudo_runner.run([
            "mount",
            "--options", ",".join(options),
            self.path,
            self.mount_point
        ])
        if result.returncode != 0:
            error("Cannot mount:", result.stderr)
            self._cleanup_mount_point(sudo_runner)
            return

    def unmount(self, sudo_runner: SudoRunner):
        print("Dismounting", self.path, "->", self.mount_point)

        result = sudo_runner.run(["umount", self.mount_point])
        if result.returncode != 0:
            error("Cannot dismount:", result.stderr)
            return

        if not self._cleanup_mount_point(sudo_runner):
            return


@dataclass
class MountableMtpDevice(MountableDevice):
    busLocation: int
    devNum: int

    def is_mounted(self) -> bool:
        # Fast but fuzzy solution. Better approach would be to call `mount`
        path = Path(self.mount_point)
        return path.exists()

    def mount(self, sudo_runner: SudoRunner):
        print("Mounting", self.name, "->", self.mount_point)

        if not self._setup_mount_point(sudo_runner):
            return

        result = subprocess.run(
            args=["jmtpfs", f"-device={self.busLocation},{self.devNum}", self.mount_point],
            capture_output=True,
            text=True,
        )
        if result.returncode != 0:
            error("Cannot mount:", result.stderr)
            self._cleanup_mount_point(sudo_runner)
            return

        path = Path(self.mount_point)
        try:
            path.stat()
        except OSError:
            error("Mounted device not accessible, enable MTP on your phone and try it again!")
            self.unmount(sudo_runner)

    def unmount(self, sudo_runner: SudoRunner):
        print("Dismounting", self.name, "->", self.mount_point)

        result = sudo_runner.run(["fusermount", "-u", self.mount_point])
        if result.returncode != 0:
            error("Cannot dismount:", result.stderr)
            return

        if not self._cleanup_mount_point(sudo_runner):
            return


@dataclass
class MountableVeraCryptDevice(MountableDevice):
    path: str
    mounted: bool

    def is_mounted(self) -> bool:
        return self.mounted

    def mount(self, sudo_runner: SudoRunner):
        print("Mounting", self.name, "->", self.mount_point)

        if not self._setup_mount_point(sudo_runner):
            return

        password = password_prompt("Enter VeraCrypt password:")
        result = sudo_runner.run([
            "veracrypt", "--text",
            "--pim", "0",
            "--keyfiles", "",
            "--protect-hidden", "no",
            f"--password={password}",
            "--mount", self.path,
            self.mount_point,
        ])
        if result.returncode != 0:
            error("Cannot mount:", result.stderr)
            self._cleanup_mount_point(sudo_runner)
            return

    def unmount(self, sudo_runner: SudoRunner):
        print("Dismounting", self.name, "->", self.mount_point)

        result = sudo_runner.run([
            "veracrypt", "--text",
            "--unmount", self.mount_point,
        ])
        if result.returncode != 0:
            error("Cannot dismount:", result.stderr)
            return

        if not self._cleanup_mount_point(sudo_runner):
            return


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
        result = self._run_lsusb()
        if result.returncode != 0:
            error("Cannot get MTP devices:", result.stderr)
            return []

        raw_device_pattern = r'^Bus (\d+) Device (\d+): ID ([0-9a-fA-F]+:[0-9a-fA-F]+) (.+MTP mode.*)$'
        raw_devices = [match.groups() for match in re.finditer(raw_device_pattern, result.stdout, re.MULTILINE)]
        return [self._parse_device(raw_device) for raw_device in raw_devices]

    @staticmethod
    def _run_lsusb() -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            args=["lsusb"],
            capture_output=True,
            text=True,
        )

    @staticmethod
    def _parse_device(raw_device: Tuple[str, ...]) -> MtpDevice:
        return MtpDevice(
            busLocation=int(raw_device[0]),
            devNum=int(raw_device[1]),
            id=raw_device[2],
            name=raw_device[3],
        )


class MountableDevicesFactory:
    def resolve(self, block_devices: List[BlockDevice], mtp_devices: List[MtpDevice]) -> List[MountableDevice]:
        mountable_devices: List[MountableDevice] = []
        for parent_device in block_devices:
            for device in parent_device.children:
                if not self.is_mountable_block(parent_device, device):
                    continue

                label = f" ({device.label}) " if device.label is not None else ""
                name = f"{device.path}[{device.fstype}]{label}"

                if device.mount_point:
                    mount_point = device.mount_point
                else:
                    mount_point = self._resolve_mount_point("/media/usb", device.path)

                mountable_devices.append(MountableBlockDevice(
                    name=name,
                    fstype=device.fstype,
                    path=device.path,
                    mount_point=mount_point,
                    mounted=bool(device.mount_point),
                ))

        for device in block_devices:
            if not self.is_mountable_vera_crypt(device):
                continue

            if len(device.children) == 1 and device.children[0].mount_point:
                mount_point = device.children[0].mount_point
            else:
                mount_point = self._resolve_mount_point("/media/encrypted", device.path)

            mountable_devices.append(MountableVeraCryptDevice(
                name=f"{device.path}[encrypted]",
                path=device.path,
                mount_point=mount_point,
                mounted=len(device.children) == 1,
            ))

        for device in mtp_devices:
            mount_point = self._resolve_mount_point("/media/android", device.name)

            mountable_devices.append(MountableMtpDevice(
                name=device.name,
                mount_point=mount_point,
                busLocation=device.busLocation,
                devNum=device.devNum,
            ))

        return mountable_devices

    @staticmethod
    def is_mountable_block(parent_device: BlockDevice, device: BlockDevice) -> bool:
        if not (parent_device.type == "disk" and parent_device.tran == "usb"):
            return False

        if device.type not in ['part', 'dm']:
            return False

        # Zero size disks are (probably) card readers w/o a card inserted in them
        if device.size == 0:
            return False

        media_mount_point_pattern = re.compile("^/media/usb")
        if device.mount_point is not None and not media_mount_point_pattern.match(device.mount_point):
            return False

        return True

    @staticmethod
    def is_mountable_vera_crypt(device: BlockDevice) -> bool:
        """Fuzzy detection of VeraCrypt encrypted devices.

        Encrypted devices does not report themselves, thus we have to employ
        some heuristics to find them, which may report false positives.
        """
        if not (device.type == "disk" and device.tran == "usb"):
            return False

        if device.size == 0:
            return False

        # It would be better to detect encrypted device by reading few bytes
        # off it, detect there is no known filesystem, and calculate entropy.
        unmounted_crypt = len(device.children) == 0
        mounted_crypt = len(device.children) == 1 and "veracrypt" in device.children[0].path
        return unmounted_crypt or mounted_crypt

    @staticmethod
    def _resolve_mount_point(prefix: str, device_name: str):
        match = re.compile("^.*/([a-z0-9-]+)$").match(device_name)
        if match:
            return f"{prefix}-{match.group(1)}"
        else:
            suffix = hashlib.md5(device_name.encode()).hexdigest()[:3]
            return f"{prefix}-{suffix}"


def password_prompt(prompt: str) -> str:
    if not sys.stdin.isatty():
        return input(prompt)

    print(f"{prompt} |", end="", flush=True)
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
                spin(i)
                password = password + ch
        return password
    finally:
        termios.tcsetattr(fd, termios.TCSADRAIN, old)
        print()


def spin(i: int):
    symbol = ('/', '-', '\\', '|')[i % 4]
    print(f"\b{symbol}", end="", flush=True)


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
        name="/dev/null[dummy]",
        fstype="unknown",
        path="/dev/null",
        mount_point="/media/usbD",
        mounted=False,
    ))

    print()
    for index, mountable_device in enumerate(mountable_devices, start=1):
        mounted = f" \033[31m*mounted*\033[0m" if mountable_device.is_mounted() else ""
        print(f"{index}) {mountable_device.name} -> {mountable_device.mount_point}{mounted}")
    print()

    device_index=read_char("Select disk:")
    if device_index.isdigit() and 0 <= int(device_index) - 1 < len(mountable_devices):
        mountable_device = mountable_devices[int(device_index) - 1]
        sudo_runner = SudoRunner()
        if mountable_device.is_mounted():
            mountable_device.unmount(sudo_runner)
        else:
            mountable_device.mount(sudo_runner)
    else:
        print("exit")


if __name__ == "__main__":
    main()