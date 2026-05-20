#!/usr/bin/env python3
import json
import os
import subprocess
import sys
import time
from typing import Optional


class AppLauncher:
    _current_workspace: Optional[int] = None

    def launch(
            self,
            workspace: int,
            check_pattern: str,
            cmd: str,
    ):
        if self._is_app_running(check_pattern):
            return

        if workspace != self._current_workspace:
            self.switch_to_workspace(workspace)

        self._start_app_detached(cmd)
        self._wait_for_app_to_start(check_pattern)

    def switch_to_workspace(self, workspace: int):
        subprocess.run(
            args=['swaymsg', 'workspace', f"{workspace}"],
            stdout=subprocess.DEVNULL,
        )
        self._current_workspace = workspace

    @staticmethod
    def _is_app_running(check_pattern: str) -> bool:
        check_pattern = check_pattern.lower()

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

                if check_pattern in app_id or check_pattern in title or check_pattern in window_class:
                    return True

                return any(search(v) for v in node.values())
            elif isinstance(node, list):
                return any(search(i) for i in node)
            return False

        return search(tree)

    def _wait_for_app_to_start(self, pattern: str):
        while not self._is_app_running(pattern):
            time.sleep(1)

    def _start_app_detached(self, cmd: str):
        args = self._prepare_cmd(cmd)
        subprocess.Popen(
            args=args,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            stdin=subprocess.DEVNULL,
            start_new_session=True
        )

    def _prepare_cmd(self, cmd: str) -> list[str]:
        tokens = self._tokenize_cmd(cmd)
        home = os.path.expanduser("~")
        return [token.replace("$HOME", home) for token in tokens]

    @staticmethod
    def _tokenize_cmd(cmd: str) -> list[str]:
        opening_quote = ""
        current_token = ""
        tokens = []
        for ch in cmd:
            if (ch == "'" or ch == '"') and not opening_quote:
                opening_quote = ch
            elif ch == opening_quote:
                opening_quote = ""

            if ch == " " and not opening_quote:
                if current_token:
                    tokens.append(current_token)
                current_token = ""
            else:
                current_token += ch
        if current_token:
            tokens.append(current_token)

        return tokens


def main():
    app_launcher = AppLauncher()

    app_launcher.launch(
        workspace=10,
        check_pattern="thunderbird",
        cmd="thunderbird",
    )

    app_launcher.launch(
        workspace=10,
        check_pattern="signal",
        cmd="signal-desktop",
    )

    app_launcher.launch(
        workspace=2,
        check_pattern="firefox",
        cmd="firefox",
    )

    app_launcher.launch(
        workspace=3,
        check_pattern="jetbrains-idea",
        cmd="gtk-launch jetbrains-idea-ef52faa1-3035-4ceb-a7cb-0dfdcf75b2e1.desktop",
    )

    app_launcher.launch(
        workspace=7,
        check_pattern="nvim-qt",
        cmd="nvim-qt -- -p $HOME/Documents/tmp.md",
    )

    app_launcher.launch(
        workspace=7,
        check_pattern="Blank Box",
        cmd="blank-box",
    )

    app_launcher.switch_to_workspace(2)


if __name__ == "__main__":
    main()
