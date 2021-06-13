#!/bin/bash


if [[ $(pidof X) ]]; then
  # Found running X server, exit
  exit 0
fi

if [[ -z ${DISPLAY+x} ]]; then
  echo "Please set DISPLAY environment variable to \":0\" or other number"
  exit 1
fi

if [[ ! $(pidof Xvfb) ]]; then
  echo "Looks like no X server is running"
  if [[ $(dpkg -l xvfb | grep "Status" | wc -l) == 0 ]]; then
    echo "Please install fake X server with xvfb package"
    exit 1
  else
    echo "Launching Xvfb display"
    Xvfb $DISPLAY &
  fi
fi
