#!/usr/bin/env python3
import json
import os
import subprocess
import sys


def wait_for_window(pattern: str):
    pattern = pattern.lower()

    proc = subprocess.Popen(
        args=["swaymsg", "-t", "subscribe", '["window"]'],
        stdout=subprocess.PIPE,
        text=True
    )

    try:
        for line in proc.stdout:
            event = json.loads(line)

            if event.get("change") not in ("new", "title"):
                continue

            container = event.get("container", {})
            app_id = (container.get("app_id") or "").lower()
            title = (container.get("name") or "").lower()

            if pattern in app_id or pattern in title:
                return
    finally:
        proc.kill()


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


def start_app_detached(*cmd: str):
    subprocess.Popen(
        args=list(cmd),
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        stdin=subprocess.DEVNULL,
        start_new_session=True
    )


def switch_to_workspace(workspace: int):
    subprocess.run(
        args=['swaymsg', 'workspace', f"{workspace}"],
        stdout=subprocess.DEVNULL,
    )


def main():
    switch_to_workspace(10)

    if not is_app_running("thunderbird"):
        start_app_detached("thunderbird")
        wait_for_window("thunderbird")

    if not is_app_running("signal"):
        start_app_detached("signal-desktop")
        wait_for_window("signal")

    switch_to_workspace(2)

    if not is_app_running("firefox"):
        start_app_detached("firefox")
        wait_for_window("firefox")

    switch_to_workspace(3)

    if not is_app_running("jetbrains-idea"):
        start_app_detached("gtk-launch", "jetbrains-idea-98984e61-a56f-427f-983a-de28833912c2.desktop")
        wait_for_window("jetbrains-idea")

    switch_to_workspace(7)

    if not is_app_running("nvim-qt"):
        home = os.path.expanduser("~")
        tmp_file = os.path.join(home, "Documents/tmp.md")
        todo_file = os.path.join(home, "Documents/TODO.md")
        log_file = os.path.join(home, "Documents/log.md")
        start_app_detached("nvim-qt", "--", "-p", tmp_file, todo_file, log_file)
        wait_for_window("nvim-qt")

    if not is_app_running("Blank Box"):
        start_app_detached("blank-box")
        wait_for_window("blank-box")

    switch_to_workspace(2)


if __name__ == "__main__":
    main()
    sys.exit(0)
