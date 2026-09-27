#!/usr/bin/env python3
import subprocess
import sys
import time
from dataclasses import dataclass


@dataclass
class LockManager:
    def lock(self):
        if self.is_locked():
            return

        subprocess.run(["swaylock", "-f"])

        subprocess.Popen(
            [sys.executable, __file__, "--manage-display"],
            start_new_session=True,
        )

    @staticmethod
    def is_locked() -> bool:
        return subprocess.run(["pgrep", "-x", "swaylock"], stdout=subprocess.DEVNULL).returncode == 0


@dataclass
class DisplayManager:
    lock_manager: LockManager

    _DISPLAY_TIMEOUT_SECONDS = 60

    def manage_display(self):
        idle = subprocess.Popen([
            "swayidle", "-w",
            "timeout", f"{self._DISPLAY_TIMEOUT_SECONDS}", 'swaymsg "output * dpms off"',
            "resume", 'swaymsg "output * dpms on"',
        ])

        while self.lock_manager.is_locked():
            time.sleep(2)

        idle.terminate()
        subprocess.run(["swaymsg", "output * dpms on"])


def main():
    lock_manager = LockManager()
    display_manager = DisplayManager(lock_manager)

    if len(sys.argv) > 1 and sys.argv[1] == "--manage-display":
        display_manager.manage_display()
    else:
        lock_manager.lock()


if __name__ == "__main__":
    main()
