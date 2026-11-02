#!/usr/bin/env python3
"""Test desktop/window screen capture through xdg-desktop-portal.

Does the same thing a browser (MS Teams web, Meet, ...) does when you press
"Share screen"/"Share window": opens a ScreenCast session, asks the portal for
WINDOW (and/or MONITOR) sources, and reports the PipeWire node that comes back.

Run it *inside* your Wayland session:  ./screencast-test.py [--types window|monitor|all]
"""

import argparse
import os
import sys

import gi

gi.require_version("Gio", "2.0")
from gi.repository import Gio, GLib  # noqa: E402

BUS_NAME = "org.freedesktop.portal.Desktop"
OBJ_PATH = "/org/freedesktop/portal/desktop"
IFACE = "org.freedesktop.portal.ScreenCast"

MONITOR, WINDOW, VIRTUAL = 1, 2, 4
TYPE_NAMES = {MONITOR: "MONITOR", WINDOW: "WINDOW", VIRTUAL: "VIRTUAL"}


def decode(mask):
    names = [n for bit, n in TYPE_NAMES.items() if mask & bit]
    return ", ".join(names) if names else "<none>"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--types", default="window",
                    choices=["window", "monitor", "all"],
                    help="source types to request (default: window)")
    ap.add_argument("--multiple", action="store_true",
                    help="allow selecting more than one source")
    ap.add_argument("--play", action="store_true",
                    help="render the captured stream with gst-launch-1.0")
    args = ap.parse_args()

    for var in ("WAYLAND_DISPLAY", "XDG_CURRENT_DESKTOP"):
        print(f"{var}={os.environ.get(var, '')!r}")

    bus = Gio.bus_get_sync(Gio.BusType.SESSION, None)
    proxy = Gio.DBusProxy.new_sync(
        bus, Gio.DBusProxyFlags.NONE, None, BUS_NAME, OBJ_PATH, IFACE, None)

    version = proxy.get_cached_property("version")
    available = proxy.get_cached_property("AvailableSourceTypes")
    if available is None:
        sys.exit("ScreenCast interface not available -> no portal backend is "
                 "providing screen capture. Check that xdg-desktop-portal-wlr "
                 "is installed and that XDG_CURRENT_DESKTOP=sway is exported "
                 "before xdg-desktop-portal starts.")

    mask = available.unpack()
    print(f"ScreenCast version: {version.unpack() if version else '?'}")
    print(f"AvailableSourceTypes: {mask} ({decode(mask)})")

    wanted = {"window": WINDOW, "monitor": MONITOR,
              "all": MONITOR | WINDOW | VIRTUAL}[args.types]
    if not mask & wanted:
        print(f"\n==> Backend does NOT offer {decode(wanted)} capture. "
              "Single-window sharing is impossible with this backend.")
        if not mask:
            return 1

    unique = bus.get_unique_name()[1:].replace(".", "_")
    token_n = [0]
    loop = GLib.MainLoop()
    state = {"streams": None, "failed": None}

    def request(method, arg_sig, arg_values, options, on_response):
        token_n[0] += 1
        token = f"sct{os.getpid()}_{token_n[0]}"
        options["handle_token"] = GLib.Variant("s", token)
        path = f"/org/freedesktop/portal/desktop/request/{unique}/{token}"

        def cb(_conn, _sender, _path, _iface, _sig, params):
            bus.signal_unsubscribe(sub_id)
            code, results = params.unpack()
            if code != 0:
                state["failed"] = f"{method} cancelled/failed (code {code})"
                loop.quit()
                return
            on_response(results)

        sub_id = bus.signal_subscribe(
            BUS_NAME, "org.freedesktop.portal.Request", "Response", path,
            None, Gio.DBusSignalFlags.NONE, cb)
        proxy.call_sync(method,
                        GLib.Variant(f"({arg_sig}a{{sv}})",
                                     tuple(arg_values) + (options,)),
                        Gio.DBusCallFlags.NONE, -1, None)

    session = {}

    def on_created(results):
        session["handle"] = results["session_handle"]
        print(f"session: {session['handle']}")
        print("--> pick a source in the picker that just opened...")
        request("SelectSources", "o", (session["handle"],),
                {"types": GLib.Variant("u", wanted),
                 "multiple": GLib.Variant("b", args.multiple)},
                on_selected)

    def on_selected(_results):
        request("Start", "os", (session["handle"], ""), {}, on_started)

    def on_started(results):
        state["streams"] = results.get("streams", [])
        loop.quit()

    request("CreateSession", "", (),
            {"session_handle_token": GLib.Variant("s", f"scs{os.getpid()}")},
            on_created)

    GLib.timeout_add_seconds(120, lambda: (loop.quit(), False)[1])
    loop.run()

    if state["failed"]:
        print(f"\n==> {state['failed']}")
        return 1
    if not state["streams"]:
        print("\n==> No stream returned (timeout or empty selection).")
        return 1

    print("\n==> Capture negotiated. PipeWire streams:")
    for node_id, props in state["streams"]:
        src = props.get("source_type")
        print(f"    node id {node_id}  size={props.get('size')} "
              f"source_type={src} ({decode(src) if src else '?'})")
        if src == WINDOW:
            print("    ==> SINGLE-WINDOW capture confirmed.")
        elif src == MONITOR:
            print("    ==> This is a MONITOR stream, not a window.")

    if not args.play:
        print("\n(re-run with --play to render the stream and verify pixels)")
        return 0

    return play(proxy, session["handle"], state["streams"])


def play(proxy, session_handle, streams):
    """Open the PipeWire remote and render the stream with gst-launch-1.0."""
    import shutil
    import subprocess

    gst = shutil.which("gst-launch-1.0")
    if not gst:
        print("\ngst-launch-1.0 not found; install gstreamer1.0-tools and "
              "gstreamer1.0-pipewire to use --play.")
        return 1

    reply, fd_list = proxy.call_with_unix_fd_list_sync(
        "OpenPipeWireRemote",
        GLib.Variant("(oa{sv})", (session_handle, {})),
        Gio.DBusCallFlags.NONE, -1, None, None)
    fd = fd_list.get(reply.unpack()[0])
    os.set_inheritable(fd, True)

    node_id = streams[0][0]
    cmd = [gst, "pipewiresrc", f"fd={fd}", f"path={node_id}",
           "!", "videoconvert", "!", "autovideosink"]
    print(f"\n$ {' '.join(cmd)}")
    print("(a window with the captured content should appear; Ctrl-C to stop)")
    try:
        return subprocess.call(cmd, pass_fds=(fd,))
    except KeyboardInterrupt:
        return 0


if __name__ == "__main__":
    sys.exit(main())
