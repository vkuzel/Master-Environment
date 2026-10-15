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

import json
import re
import subprocess
import sys

MONITOR_PREFIX = "Monitor: "
WINDOW_RE = re.compile(r"^Window: (?P<title>.*) \((?P<identifier>[^()]*)\)$")


def swaymsg(message_type):
    out = subprocess.run(
        ["swaymsg", "-t", message_type, "-r"],
        check=True, capture_output=True, text=True).stdout
    return json.loads(out)


def output_rects():
    """Every active output, by name."""
    return {
        out["name"]: out["rect"]
        for out in swaymsg("get_outputs")
        if out.get("active") and out.get("rect")
    }


def visible_views(node, found):
    """Views the user can actually point at, in tree order.

    Containers without a `pid` are splits/workspaces/outputs, and `visible` is
    false for anything on an inactive workspace or in the scratchpad.
    """
    if node.get("pid") is not None and node.get("visible"):
        found.append(node)
    for child in node.get("nodes", []) + node.get("floating_nodes", []):
        visible_views(child, found)
    return found


def window_rects():
    """Visible windows grouped by title - titles are not unique."""
    by_title = {}
    for view in visible_views(swaymsg("get_tree"), []):
        by_title.setdefault(view.get("name"), []).append(view["rect"])
    return by_title


def regions(labels):
    """Map the portal's labels onto rectangles, keeping the label as slurp's."""
    try:
        outputs = output_rects()
        windows = window_rects()
    except (OSError, ValueError, KeyError, subprocess.CalledProcessError):
        return []

    lines = []
    for label in labels:
        rect = None
        if label.startswith(MONITOR_PREFIX):
            name = label[len(MONITOR_PREFIX):].split(" ")[0]
            rect = outputs.get(name)
        else:
            match = WINDOW_RE.match(label)
            if match:
                # Several windows can share a title; hand them out in order so
                # each label still ends up on a rectangle of its own.
                candidates = windows.get(match.group("title"))
                if candidates:
                    rect = candidates.pop(0)

        if rect and rect["width"] > 0 and rect["height"] > 0:
            lines.append(
                f"{rect['x']},{rect['y']} "
                f"{rect['width']}x{rect['height']} {label}")
    return lines


def choose(command, stdin, labels):
    """Run a chooser, return the label it selected, or None when cancelled."""
    try:
        result = subprocess.run(
            command, input=stdin, capture_output=True, text=True)
    except OSError:
        return None
    if result.returncode != 0 or not result.stdout:
        return None

    # The portal matches the answer against its own labels verbatim, so always
    # reply with the original line - a label can end in a space (an output
    # without a description) and choosers tend to trim that away.
    selected = result.stdout.splitlines()[0]
    for label in labels:
        if label.rstrip() == selected.rstrip():
            return label
    return None


def main():
    labels = [line for line in sys.stdin.read().splitlines() if line]
    if not labels:
        return 1

    lines = regions(labels)
    if lines:
        # -r restricts the selection to the rectangles read from stdin, -f %l
        # prints the label of the one that was picked.
        label = choose(["slurp", "-r", "-f", "%l"], "\n".join(lines) + "\n",
                       labels)
    else:
        label = choose(
            ["fuzzel", "--dmenu", "--lines", "10", "--prompt", "Share: "],
            "\n".join(labels) + "\n", labels)

    if label is None:
        return 0
    print(label)
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as error:  # never exit 127, that means "no chooser"
        print(f"share-picker: {error}", file=sys.stderr)
        sys.exit(1)
