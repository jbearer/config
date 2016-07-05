#!/usr/bin/env bash

# Install packages
for pkg_list in `ls packages`; do
  source packages/$pkg_list
done

curl "https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh" -o "~/.git-prompt.sh"

CONFIG="${HOME}/.config"

mkdir "${CONFIG}/i3"
mkdir "${CONFIG}/i3status"

# Symlink all the things

# bash config
ln -s `pwd`/.bashrc                  "${HOME}/.bashrc"
ln -s `pwd`/.bash_aliases            "${HOME}/.bash_aliases"

# gdb config
ln -s `pwd`/.gdbinit                 "${HOME}/.gdbinit"

# i3 config
ln -s `pwd`/i3/config                "${CONFIG}/i3/config"
ln -s `pwd`/i3status/config          "${CONFIG}/i3status/config"

# Sublime settings
ls -1 sublime/settings | while read f; do
  ln -s "`pwd`/sublime/settings/${f}" "${CONFIG}/sublime-text-3/Packages/User/${f}"
done

source .bashrc
