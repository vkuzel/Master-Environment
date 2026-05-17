#!/usr/bin/env python3
import json
import os
import subprocess
import sys
import time


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

    thunderbird_pattern = "thunderbird"
    if not is_app_running(thunderbird_pattern):
        start_app_detached("thunderbird")
        wait_for_app_to_start(thunderbird_pattern)

    signal_pattern = "signal"
    if not is_app_running(signal_pattern):
        start_app_detached("signal-desktop")
        wait_for_app_to_start(signal_pattern)

    switch_to_workspace(2)

    firefox_pattern = "firefox"
    if not is_app_running(firefox_pattern):
        start_app_detached("firefox")
        wait_for_app_to_start(firefox_pattern)

    switch_to_workspace(3)

    idea_pattern = "jetbrains-idea"
    if not is_app_running(idea_pattern):
        start_app_detached("gtk-launch", "jetbrains-idea-ef52faa1-3035-4ceb-a7cb-0dfdcf75b2e1.desktop")
        wait_for_app_to_start(idea_pattern)

    switch_to_workspace(7)

    neo_vim_pattern = "nvim-qt"
    if not is_app_running(neo_vim_pattern):
        home = os.path.expanduser("~")
        tmp_file = os.path.join(home, "Documents/tmp.md")
        start_app_detached("nvim-qt", "--", "-p", tmp_file)
        wait_for_app_to_start(neo_vim_pattern)

    blank_box_pattern = "Blank Box"
    if not is_app_running(blank_box_pattern):
        start_app_detached("blank-box")
        wait_for_app_to_start(blank_box_pattern)

    switch_to_workspace(2)


if __name__ == "__main__":
    main()
    sys.exit(0)
