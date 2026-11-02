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

    _SWAYLOCK_PATTERN = r"(^|/)swaylock( |$)"

    @classmethod
    def is_locked(cls) -> bool:
        return subprocess.run(
            ["pgrep", "-f", cls._SWAYLOCK_PATTERN], stdout=subprocess.DEVNULL
        ).returncode == 0


@dataclass
class DisplayManager:
    lock_manager: LockManager

    _DISPLAY_TIMEOUT_SECONDS = 60
    _POLL_INTERVAL_SECONDS = 2
    _LOCK_WAIT_SECONDS = 10

    def manage_display(self):
        if not self._wait_for_lock():
            return

        idle = subprocess.Popen([
            "swayidle", "-w",
            "timeout", f"{self._DISPLAY_TIMEOUT_SECONDS}", 'swaymsg "output * dpms off"',
            "resume", 'swaymsg "output * dpms on"',
        ])

        while self.lock_manager.is_locked():
            time.sleep(self._POLL_INTERVAL_SECONDS)

        idle.terminate()
        idle.wait()
        subprocess.run(["swaymsg", "output * dpms on"])

    def _wait_for_lock(self) -> bool:
        deadline = time.monotonic() + self._LOCK_WAIT_SECONDS
        while not self.lock_manager.is_locked():
            if time.monotonic() >= deadline:
                return False
            time.sleep(0.2)
        return True


def main():
    lock_manager = LockManager()
    display_manager = DisplayManager(lock_manager)

    if len(sys.argv) > 1 and sys.argv[1] == "--manage-display":
        display_manager.manage_display()
    else:
        lock_manager.lock()


if __name__ == "__main__":
    main()
