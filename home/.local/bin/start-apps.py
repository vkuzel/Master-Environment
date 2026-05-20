#!/usr/bin/env python3
import json
import os
import subprocess
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Optional

import yaml


@dataclass
class App:
    workspace: int
    check_pattern: Optional[str] = None
    cmd: Optional[str] = None


class AppLoader:

    def load(self) -> list[App]:
        override_config_path = self._resolve_config_file_path("override-apps.yaml")
        if override_config_path.is_file():
            return self._load_from_file(override_config_path)

        default_config_path = self._resolve_config_file_path("apps.yaml")
        if default_config_path.is_file():
            return self._load_from_file(default_config_path)

        return []

    @staticmethod
    def _resolve_config_file_path(file_name: str) -> Path:
        home = os.path.expanduser("~")
        return Path(home, ".config", "app-launcher", file_name)

    @staticmethod
    def _load_from_file(config_path: Path) -> list[App]:
        with open(config_path) as f:
            data = yaml.safe_load(f)

        return [App(**item) for item in data]


class AppLauncher:
    _current_workspace: Optional[int] = None

    def launch(self, app: App):
        if app.workspace != self._current_workspace:
            self._switch_to_workspace(app.workspace)

        if not app.check_pattern or not app.cmd:
            return

        if self._is_app_running(app.check_pattern):
            return

        self._start_app_detached(app.cmd)
        self._wait_for_app_to_start(app.check_pattern)

    def _switch_to_workspace(self, workspace: int):
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
    app_loader = AppLoader()
    app_launcher = AppLauncher()

    apps = app_loader.load()
    for app in apps:
        app_launcher.launch(app)


if __name__ == "__main__":
    main()
