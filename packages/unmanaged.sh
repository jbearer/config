#!/usr/bin/env bash

add_package()
{
  echo "Installing $1"
  curl -o "/tmp/downloaded.deb" "$1"
  sudo dpkg -i "/tmp/downloaded.deb"
  rm "/tmp/downloaded.deb"
}

add_package "https://download.sublimetext.com/sublime-text_build-3126_amd64.deb"

apt-get install -f
