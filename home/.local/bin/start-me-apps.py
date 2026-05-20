#!/usr/bin/env python3
import json
import os
import subprocess
import sys
import time
from typing import Optional


def is_app_running(pattern: str) -> bool:
    pattern = pattern.lower()

    result = subprocess.run(
        ["swaymsg", "-t", "get_tree"],
        capture_output=True,
        text=True,
    )
    tree = json.loads(result.stdout)

    def search(node):
        if isinstance(node, dict):
            app_id = (node.get("app_id") or "").lower()
            title = (node.get("title") or "").lower()
            window_class = (node.get("class") or "").lower()

            if pattern in app_id or pattern in title or pattern in window_class:
                return True

            return any(search(v) for v in node.values())
        elif isinstance(node, list):
            return any(search(i) for i in node)
        return False

    return search(tree)


def wait_for_app_to_start(pattern: str):
    while not is_app_running(pattern):
        time.sleep(1)


def start_app_detached(cmd: list[str]):
    subprocess.Popen(
        args=cmd,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        stdin=subprocess.DEVNULL,
        start_new_session=True
    )


def ensure_app_running(check_running_pattern: str, cmd: list[str]):
    if is_app_running(check_running_pattern):
        return

    start_app_detached(*cmd)
    wait_for_app_to_start(check_running_pattern)


class AppLauncher:
    _current_workspace: Optional[int] = None

    def launch(
            self,
            workspace: int,
            check_pattern: str,
            cmd: list[str],
    ):
        if is_app_running(check_pattern):
            return

        if workspace != self._current_workspace:
            self.switch_to_workspace(workspace)

        start_app_detached(*cmd)
        wait_for_app_to_start(check_pattern)

    def switch_to_workspace(self, workspace: int):
        subprocess.run(
            args=['swaymsg', 'workspace', f"{workspace}"],
            stdout=subprocess.DEVNULL,
        )
        self._current_workspace = workspace


def main():
    app_launcher = AppLauncher()

    app_launcher.launch(
        workspace=10,
        check_pattern="thunderbird",
        cmd=["thunderbird"],
    )

    app_launcher.launch(
        workspace=10,
        check_pattern="signal",
        cmd=["signal-desktop"],
    )

    app_launcher.launch(
        workspace=2,
        check_pattern="firefox",
        cmd=["firefox"],
    )

    app_launcher.launch(
        workspace=3,
        check_pattern="jetbrains-idea",
        cmd=["gtk-launch", "jetbrains-idea-ef52faa1-3035-4ceb-a7cb-0dfdcf75b2e1.desktop"],
    )

    home = os.path.expanduser("~")
    tmp_file = os.path.join(home, "Documents/tmp.md")
    app_launcher.launch(
        workspace=7,
        check_pattern="nvim-qt",
        cmd=["nvim-qt", "--", "-p", tmp_file],
    )

    app_launcher.launch(
        workspace=7,
        check_pattern="Blank Box",
        cmd=["blank-box"],
    )

    app_launcher.switch_to_workspace(2)


if __name__ == "__main__":
    main()
    sys.exit(0)
