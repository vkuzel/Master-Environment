#!/bin/bash

setsid foot --title="microgui" -e micro "$@" > /dev/null 2>&1 &
