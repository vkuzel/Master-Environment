#!/bin/bash

setsid foot --title="microgui" -e micro --parsecursor=True "$@" > /dev/null 2>&1 &
