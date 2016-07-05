#!/usr/bin/env bash

add_package()
{
  wget -O downloaded.deb "$1"
  dpkg -i downloaded.deb
  rm downloaded.deb
}

add_package "https://download.sublimetext.com/sublime-text_build-3114_amd64.deb"
