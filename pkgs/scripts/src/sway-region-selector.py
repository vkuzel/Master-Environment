#!/usr/bin/env python3
from dataclasses import dataclass

import json
import re
import subprocess
import sys

from typing import Any, Dict, List, Optional, cast

Rect = Dict[str, int]
Node = Dict[str, Any]


@dataclass(frozen=True)
class Label:
    text: str


@dataclass(frozen=True)
class MonitorLabel(Label):
    name: str


@dataclass(frozen=True)
class WindowLabel(Label):
    title: str


class LabelParser:
    _MONITOR_PREFIX = "Monitor: "
    _WINDOW_RE = re.compile(r"^Window: (?P<title>.*) \((?P<identifier>[^()]*)\)$")

    def parse(self, stdin: str) -> List[Label]:
        lines = stdin.splitlines()

        labels = []
        for line in lines:
            if line.startswith(self._MONITOR_PREFIX):
                name = line[len(self._MONITOR_PREFIX):].split(" ")[0]
                labels.append(MonitorLabel(line, name))
            else:
                match = self._WINDOW_RE.match(line)
                if match:
                    title = match.group("title")
                    labels.append(WindowLabel(line, title))
        return labels


@dataclass(frozen=True)
class Region:
    label: Label
    x: int
    y: int
    width: int
    height: int

    def to_slurp_line(self) -> str:
        return f"{self.x},{self.y} {self.width}x{self.height} {self.label.text}"


class RegionParser:

    def parse(self, labels: List[Label]) -> List[Region]:
        outputs = self._output_rects()
        windows = self._window_rects()

        regions = []
        for label in labels:
            rect = None
            if isinstance(label, MonitorLabel):
                rect = outputs.get(label.name)
            elif isinstance(label, WindowLabel):
                rect = windows.get(label.title)

            if rect and rect["width"] > 0 and rect["height"] > 0:
                regions.append(Region(
                    label=label,
                    x=rect["x"],
                    y=rect["y"],
                    width=rect["width"],
                    height=rect["height"],
                ))
        return regions

    @staticmethod
    def _output_rects() -> Dict[str, Rect]:
        sway_outputs = RegionParser._swaymsg("get_outputs")

        return {
            out["name"]: out["rect"]
            for out in sway_outputs
            if out.get("active") and out.get("rect")
        }

    @staticmethod
    def _window_rects() -> Dict[str, Rect]:
        sway_tree = RegionParser._swaymsg("get_tree")

        by_title = {}
        for view in RegionParser._visible_views(sway_tree, []):
            view_name = cast(str, view.get("name"))
            by_title.setdefault(view_name, []).append(view["rect"])

        # only windows with unique name (otherwise windows could be selected randomly
        # we'll ignore windows with duplicate titles
        by_title_unique = {}
        for title, rects in by_title.items():
            if len(rects) == 1:
                by_title_unique[title] = rects[0]

        return by_title_unique

    @staticmethod
    def _visible_views(node: Node, found: List[Node]) -> List[Node]:
        if node.get("pid") is not None and node.get("visible"):
            found.append(node)
        for child in node.get("nodes", []) + node.get("floating_nodes", []):
            RegionParser._visible_views(child, found)
        return found

    @staticmethod
    def _swaymsg(message_type: str) -> Any:
        out = subprocess.run(
            ["swaymsg", "-t", message_type, "-r"],
            check=True,
            capture_output=True,
            text=True,
        ).stdout
        return json.loads(out)


class RegionSelector:

    def select(self, regions: List[Region]) -> Optional[Label]:
        lines = [region.to_slurp_line() for region in regions]
        selected_line = self._slurp(lines)
        if selected_line is None:
            return None

        for region in regions:
            if region.label.text.rstrip() == selected_line.rstrip():
                return region.label
        return None

    @staticmethod
    def _slurp(lines: List[str]) -> Optional[str]:
        try:
            result = subprocess.run(
                args=["slurp", "-r", "-f", "%l"],
                input="\n".join(lines) + "\n",
                capture_output=True,
                text=True,
            )
        except OSError:
            return None
        if result.returncode != 0 or not result.stdout:
            return None

        return result.stdout.splitlines()[0]


def main() -> int:
    label_parser = LabelParser()
    region_parser = RegionParser()
    region_selector = RegionSelector()

    stdin = sys.stdin.read()
    labels = label_parser.parse(stdin)
    if not labels:
        return 1

    regions = region_parser.parse(labels)

    selected_label = region_selector.select(regions)
    if selected_label is None:
        return 0

    print(selected_label.text)
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as error:
        print(f"region-selector: {error}", file=sys.stderr)
        sys.exit(1)
