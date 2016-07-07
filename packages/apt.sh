#!/usr/bin/env bash
#
# Install packages from apt

# Set up i3 repository
i3pkg="deb http://debian.sur5r.net/i3/ $(lsb_release -c -s) universe"
if ! grep "$i3pkg" /etc/apt/sources.list; then
  echo "$i3pkg" >> /etc/apt/sources.list
fi
apt-get update
apt-get --allow-unauthenticated install sur5r-keyring

# Set upt chrome repository
wget -q -O - "https://dl-ssl.google.com/linux/linux_signing_key.pub" | apt-key add -
chromepkg="deb http://dl.google.com/linux/chrome/deb/ stable main"
if ! grep "$chromepkg" /etc/apt/sources.list.d/google-chrome.list; then
	echo "$chromepkg" >> /etc/apt/sources.list.d/google-chrome.list
fi

# Update with new repositories
apt-get update

add_package()
{
  apt-get -y install $1
}

# Packages
add_package i3
add_package google-chrome-stable
add_package xbacklight
