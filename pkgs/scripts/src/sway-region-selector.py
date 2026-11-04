#!/usr/bin/env python3
"""Pick a screen-share source with the mouse instead of from a list.

xdg-desktop-portal-wlr runs this program when an application (Firefox, Teams,
Meet, ...) asks to share the screen. It is the portal's "dmenu" chooser: the
available sources arrive on stdin, one label per line,

    Monitor: <name> <description>
    Window: <title> (<identifier>)

and exactly one of those lines has to be written back on stdout. Printing
nothing means the user cancelled.

Rather than showing a menu, every label is turned back into a rectangle on
screen - window geometry comes from the sway tree, monitor geometry from sway's
outputs - and the rectangles are handed to `slurp -r`, which dims the desktop
and lets the source be picked by pointing at it. slurp always highlights the
*smallest* rectangle under the cursor, so pointing at a window shares that
window and pointing at the bar or a gap shares the whole monitor behind it.

If the geometry cannot be resolved (sway not reachable, nothing visible), the
script falls back to the plain fuzzel list, so sharing keeps working.
"""
from dataclasses import dataclass

import json
import re
import subprocess
import sys
from typing import Any, Dict, List, Optional

Rect = Dict[str, int]
Node = Dict[str, Any]


@dataclass(frozen=True)
class Label:
    description: str


class LabelParser:

    @staticmethod
    def parse(stdin: str) -> List[Label]:
        lines = stdin.splitlines()
        return [Label(line) for line in lines if line]


@dataclass(frozen=True)
class Region:
    label: Label
    x: int
    y: int
    width: int
    height: int

    def to_slurp_line(self) -> str:
        return f"{self.x},{self.y} {self.width}x{self.height} {self.label.description}"


class RegionParser:
    _MONITOR_PREFIX = "Monitor: "
    _WINDOW_RE = re.compile(r"^Window: (?P<title>.*) \((?P<identifier>[^()]*)\)$")

    def parse(self, labels: List[Label]) -> List[Region]:
        """Map the portal's labels onto rectangles, keeping the label as slurp's."""
        try:
            outputs = self._output_rects()
            windows = self._window_rects()
        except (OSError, ValueError, KeyError, subprocess.CalledProcessError):
            return []

        regions: List[Region] = []
        for label in labels:
            rect: Optional[Rect] = None
            if label.description.startswith(self._MONITOR_PREFIX):
                name = label.description[len(self._MONITOR_PREFIX):].split(" ")[0]
                rect = outputs.get(name)
            else:
                match = self._WINDOW_RE.match(label.description)
                if match:
                    # Several windows can share a title; hand them out in order so
                    # each label still ends up on a rectangle of its own.
                    candidates = windows.get(match.group("title"))
                    if candidates and len(candidates) == 1:
                        rect = candidates.pop(0)

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
    def _window_rects() -> Dict[str, List[Rect]]:
        """Visible windows grouped by title - titles are not unique."""
        by_title: Dict[str, List[Rect]] = {}
        for view in RegionParser._visible_views(RegionParser._swaymsg("get_tree"), []):
            by_title.setdefault(view.get("name"), []).append(view["rect"])
        return by_title

    @staticmethod
    def _output_rects() -> Dict[str, Rect]:
        """Every active output, by name."""
        return {
            out["name"]: out["rect"]
            for out in RegionParser._swaymsg("get_outputs")
            if out.get("active") and out.get("rect")
        }

    @staticmethod
    def _visible_views(node: Node, found: List[Node]) -> List[Node]:
        """Views the user can actually point at, in tree order.

        Containers without a `pid` are splits/workspaces/outputs, and `visible` is
        false for anything on an inactive workspace or in the scratchpad.
        """
        if node.get("pid") is not None and node.get("visible"):
            found.append(node)
        for child in node.get("nodes", []) + node.get("floating_nodes", []):
            RegionParser._visible_views(child, found)
        return found

    @staticmethod
    def _swaymsg(message_type: str) -> Any:
        out = subprocess.run(
            ["swaymsg", "-t", message_type, "-r"],
            check=True, capture_output=True, text=True).stdout
        return json.loads(out)


class RegionSelector:

    def select(self, labels: List[Label], regions: List[Region]) -> Optional[Label]:
        lines = [region.to_slurp_line() for region in regions]
        selected_line = self._slurp(lines)
        if selected_line is None:
            return None

        for region in regions:
            if region.label.description.rstrip() == selected_line.rstrip():
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

    label = region_selector.select(labels, regions)
    if label is None:
        return 0

    print(label.description)
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as error:  # never exit 127, that means "no chooser"
        print(f"region-selector: {error}", file=sys.stderr)
        sys.exit(1)
