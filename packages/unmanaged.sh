#!/usr/bin/env bash

add_package()
{
  curl -s -o "/tmp/downloaded.deb" "$1"
  dpkg -i "/tmp/downloaded.deb"
  rm "/tmp/downloaded.deb"
}

add_package "https://download.sublimetext.com/sublime-text_build-3114_amd64.deb"

apt-get install -f
