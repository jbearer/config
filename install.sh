#!/usr/bin/env bash

filetype() # filepath
{
    ftype="<unknown file type>"
    if [[ -f "$1" ]]; then
        ftype="file"
    elif [[ -d "$1" ]]; then
        ftype="directory"
    fi
    echo "$ftype"
}

confirm() # prompt
{
    if $FORCE; then
        return 0
    fi

    echo -n "$1 "
    read -n 1 response
    echo "" # Newline
    if [[ "$response" != "y" ]]; then
        return 1
    fi
}

remove_opt() # target
{
    if [[ -e "$1" ]]; then
        ftype=`filetype "$1"`
        if ! confirm "Overwrite existing $ftype $1?"; then
            return 1
        fi

        echo "Removing existing $ftype $1"
        rm -rf "$1"
    fi
}

setpriv() # src dst
{
    owner="`stat -c "%U" "$1"`"
    group="`stat -c "%G" "$1"`"

    if [[ "$owner" != "root" ]]; then
        owner="$USER"
    fi

    if [[ "$group" != "root" ]]; then
        group="$USER"
    fi

    chown "$owner" "$2"
    chgrp "$group" "$2"
}

overwrite_opt() # src dst
{
    if ! remove_opt "$2"; then
        return 1
    fi

    ftype=`filetype "$1"`
    echo "Installing $ftype $2 from $1"

    mkdir --parents `dirname $2`
    setpriv "`dirname $1`" "`dirname $2`" # Correct the owner/group of the new directory
    ln -s "$1" "$2"
}

install_files()
{
    echo "Searching directory ${1} for install files"

    if [[ -e "${1}.prefix" ]]; then
        # symlink files in this directory
        eval "prefix=`cat ${1}.prefix`"
        for f in `find "$1" -maxdepth 1 ! -wholename "${1}.prefix" ! -wholename "$1"`; do
            target="$f"
            linkname="${prefix}`basename $f`"

            overwrite_opt "$target" "$linkname"
        done
    else
        # search nested diretories
        for dir in `ls --file-type "$1" | grep /`; do
            install_files "${1}${dir}"
        done
    fi
}

contains()
{
    for elem in $1; do
        if [[ "$2" == "$elem" ]]; then
            return 0
        fi
    done

    return 1
}

# Confirm we have root privileges
if [[ "$USER" != "root" ]]; then
    echo "Permission denied! Are you root?"
    exit 1
fi

# We know we're root now, we'll repurpose $USER to denote the user who is installing
unset USER

# Parse options

FORCE=false
PACKAGES=false
FILES=false

while getopts "fu:" opt; do
    case "$opt" in
        f )
            FORCE=true
            ;;
        u )
            USER="$OPTARG"
            ;;
        * )
            exit 1
            ;;
    esac
done

# Positional arguments
shift `expr $OPTIND - 1`
for arg in $@; do
    case "$arg" in
        packages )
            PACKAGES=true
            ;;
        files )
            FILES=true
            ;;
        * )
            echo "Invalid positional argument $arg"
            exit 1
            ;;
    esac
done

if ! $PACKAGES && ! $FILES; then
    # Default to installing everything
    PACKAGES=true
    FILES=true
fi

# Validate inputs

if [[ -z "$USER" ]]; then
    USER=`users | cut -d " " -f 1`
    if ! confirm "No user specified. Use default $USER?"; then
        echo "Please specify a user."
        exit 1
    fi
fi

if ! contains "`users` root" "$USER"; then
    echo "Invalid user $USER"
    exit 1
fi

# Begin installation

if $PACKAGES; then
    for pkg_list in `ls packages`; do
      source packages/$pkg_list
    done

    # Add-ons for some packages
    echo "Instaling gdb stl pretty-printers"
    mkdir --parents "$HOME/gdb/python"
    svn co "svn://gcc.gnu.org/svn/gcc/trunk/libstdc++-v3/python" "$HOME/gdb/python"

    # Set up j4-make-config
    echo "Installing j4-make-config"
    if remove_opt "/tmp/downloaded.zip" && remove_opt "/tmp/downloaded"; then
        wget -O "/tmp/downloaded.zip" "https://github.com/okraits/j4-make-config/archive/master.zip"
        unzip -d "/tmp/downloaded" "/tmp/downloaded.zip"
        rm -f "/tmp/downloaded.zip"
        root=`ls "/tmp/downloaded"`

        # Install executable
        mv "/tmp/downloaded/$root/j4-make-config" "/usr/bin"

        # Update themes as user
        mv -f /tmp/downloaded/$root/themes/* "files/i3/themes"
        for file in `ls files/i3/themes`; do
            chown "$USER" "$file"
            chgrp "$USER" "$file"
        done
        sudo -u "$USER" git add -u; git commit -m "Updated j4-make-config themes"; git push

        rm -rf "/tmp/downloaded"
    fi
fi

if $FILES; then
    # Download git shell prompt
    curl "https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh" -o "$HOME/.git_prompt.sh"

    install_files `pwd`/files/
fi

# Update everything
if [[ -e "$HOME/.bashrc" ]]; then
    source "$HOME/.bashrc"
fi

if which "j4-make-config"; then
    sudo -u "$USER" touch "$HOME/.config/i3/config.local"
    j4-make-config -a "$HOME/.config/i3/config.local" -r none
fi
