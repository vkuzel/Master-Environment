#!/bin/sh

if [[ -f flake.lock && ! -O flake.lock ]]; then
  sudo chown "$(id -u):$(id -g)" flake.lock
fi
