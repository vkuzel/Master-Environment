#!/bin/bash

appName=$1

if [[ -z "$appName" ]]; then
  echo "No application name provided"
  exit 1
fi

apps=$(ps auxww | grep -i "$appName" | grep -Ev "kill.sh|grep -i")
if [[ -z "$apps" ]]; then
  echo "No processes found"
  exit 1
fi

echo
echo "$apps" | grep -Eo ".{0,20}$appName.{0,20}"

echo
read -p "Kill above processes [Y/n]" answer
if [[ "y" == "$answer" || "Y" == "$answer" || -z "$answer" ]]; then
  echo "$apps" | awk '{ print $2 }' | xargs kill
fi
