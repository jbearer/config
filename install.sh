#!/usr/bin/env bash

for opt in $@; do
    case "$opt" in
        "-d"|"--debug" )
            DEBUG=1
            ;;
    esac
done

if [[ -z "$DEBUG" ]] ; then
    echo "The installation script may delete and/or overwrite existing files. Proceed anyway? y\n"
    read response
    if [[ "$response" != "y" ]]; then
        exit 1
    fi
fi

if [[ -z "$DEBUG" ]] ; then
    # Install packages
    for pkg_list in `ls packages`; do
      source packages/$pkg_list
    done

    curl "https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh" -o "~/.git-prompt.sh"
fi

lsdir()
{
    ls --file-type $1 | grep /
}

install_files()
{
    echo "Searching directory ${1} for install files"

    if find "$1" -maxdepth 1 -name .prefix | fgrep "${1}.prefix" > /dev/NUL; then
        # symlink files in this directory
        eval "prefix=`cat ${1}.prefix`"
        for f in `find "$1" -maxdepth 1 -type f`; do
            target="$f"
            base=`basename "$f"`

            if [[ "$base" == ".prefix" ]]; then
                continue
            fi

            echo "Installing ${prefix}${base} from ${target}"
            mkdir --parents "$prefix"
            ln -s "$target" "${prefix}${base}"
        done
    fi

    # recurse on nested diretories
    for dir in `ls --file-type "$1" | grep /`; do
        install_files "${1}${dir}"
    done
}

install_files `pwd`/files/

source files/home/.bashrc
