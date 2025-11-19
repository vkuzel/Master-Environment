#!/usr/bin/env python3
from dataclasses import dataclass
import subprocess
import json
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
    name: str
    path: str
    mountpoint: Optional[str]


def resolve_mountable_devices(block_devices: List[BlockDevice]) -> List[MountableDevice]:
    mountable_devices: List[MountableDevice] = []
    for block_device in block_devices:
        if block_device.tran is not None or block_device.tran is "usb":
            continue

        mountable_devices.append(MountableDevice(
            name="whatever",
            path=block_device.path,
            mountpoint=block_device.mountpoint,
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
    pprint(block_devices)
    mountable_devices = resolve_mountable_devices(block_devices)
    pprint(mountable_devices, width=120)
