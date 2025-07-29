#!/bin/bash

export XDG_CURRENT_DESKTOP=sway
# Run sway in D-Bus session to allow screensharing
dbus-run-session sway
