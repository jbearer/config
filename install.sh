#!/usr/bin/env bash

exists()
{
    find `dirname "$1"` -maxdepth 1 -name `basename "$1"` | fgrep "$1" > /dev/null
}

confirm_overwrite()
{
    echo -n "Overwrite existing file $1? "
    read -n 1 response
    echo "" # Newline

    if [[ "$response" == "y" ]]; then
        return 0
    else
        return 1
    fi
}

install_files()
{
    echo "Searching directory ${1} for install files"

    if exists "${1}.prefix"; then
        # symlink files in this directory
        eval "prefix=`cat ${1}.prefix`"
        for f in `find "$1" -maxdepth 1 -type f`; do
            target="$f"
            base=`basename "$f"`
            linkname="${prefix}${base}"

            if [[ "$base" == ".prefix" ]]; then
                continue
            fi

            if exists "$linkname"; then
                if ! $FORCE; then
                    if ! confirm_overwrite "$linkname"; then
                        continue
                    fi
                fi

                echo "Removing existing file $linkname"
                rm -f "$linkname"
            fi

            echo "Installing $linkname from ${target}"
            mkdir --parents "$prefix"
            ln -s "$target" "$linkname"
        done
    fi

    # recurse on nested diretories
    for dir in `ls --file-type "$1" | grep /`; do
        install_files "${1}${dir}"
    done
}

FORCE=false

for opt in $@; do
    case "$opt" in
        "-f"|"--force" )
            FORCE=true
            ;;
    esac
done

# Install packages
for pkg_list in `ls packages`; do
  source packages/$pkg_list
done

# Download git shell prompt
curl "https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh" -o "$HOME/.git_prompt.sh"

install_files `pwd`/files/

source files/home/.bashrc
