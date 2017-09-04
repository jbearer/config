#!/usr/bin/env bash

set -a

info()
{
    echo "[INFO] $@"
}

warn()
{
    echo "[WARN] $@"
}

error()
{
    echo "[ERROR] $@"
}

fatal()
{
    error "$@"
    exit 1
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

remove_opt() # target
{
    if [[ -e "$1" ]]; then
        ftype=`filetype "$1"`
        if ! confirm "Overwrite existing $ftype $1?"; then
            return 1
        fi

        info "Removing existing $ftype $1"
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
    src="$1"
    dst="$2"

    previous="/tmp/`basename "$dst"`.old"

    if [[ -e "$dst" ]]; then
        if ! cp -r "$dst" "$previous"; then
            if ! confirm "Unable to save existing file system state. Any subsequent errors cannot be rolled back. Proceed anyway?"; then
                return 1
            fi
        fi
    fi

    if ! remove_opt "$dst"; then
        return 1
    fi

    ftype=`filetype "$src"`
    info "Installing $ftype $dst from $src"

    mkdir --parents "`dirname "$dst"`"
    setpriv "`dirname "$src"`" "`dirname "$dst"`" # Correct the owner/group of the new directory
    ln -s "$src" "$dst"

    info "Verifying installation of $dst"
    if ! diff -r "$src" "$dst"; then
        if [[ -e "$previous" ]]; then
            error "Detected inconsistency in installation of $dst, falling back to previous version"
            if cp "$previous" "$dst"; then
                warn "Successfully reverted installation of $dst"
            else
                fatal "Unable to revert installation of $dst, check for consistency and retry"
            fi
        else
            error "Detected inconsistency in installation of $dst, removing"
            if rm -r "$dst" && rmdir -p "`dirname "$dst"`"; then
                warn "Successfully reverted installation of $dst"
            else
                fatal "Unable to revert installation of $dst, check for consistency and retry"
            fi
        fi
    else
        info "Successfully installed $dst"
    fi

    if [[ -e "$previous" ]]; then
        rm -r "$previous"
    fi
}

install_files()
{
    info "Searching directory ${1} for install files"

    if [[ -e "${1}.prefix" ]]; then
        # symlink files in this directory
        #SPACE=' '
        eval "prefix=\"`cat ${1}.prefix`\""
        find "$1" -maxdepth 1 ! -wholename "${1}.prefix" ! -wholename "$1" -exec bash -c '
            target="{}"
            linkname="$prefix"`basename "$target"`
            overwrite_opt "$target" "$linkname"
        ' ';'
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
    fatal "Permission denied! Are you root?"
fi

# We know we're root now, we'll repurpose $USER to denote the user who is installing
unset USER

# Parse options

FORCE=false
PACKAGES=false
FILES=false
FILE_ROOT=""

while getopts "fu:r:" opt; do
    case "$opt" in
        f )
            FORCE=true
            ;;
        u )
            USER="$OPTARG"
            ;;
        r )
            FILE_ROOT="$OPTARG"
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
        fatal "Please specify a user."
    fi
fi

if ! contains "`users` root" "$USER"; then
    fatal "Invalid user $USER"
fi

# Begin installation

if $PACKAGES; then
    for pkg_list in `ls packages`; do
      source packages/$pkg_list
    done

    # Add-ons for some packages
    info "Instaling gdb stl pretty-printers"
    mkdir --parents "$HOME/gdb/python"
    svn co "svn://gcc.gnu.org/svn/gcc/trunk/libstdc++-v3/python" "$HOME/gdb/python"

    # Set up j4-make-config
    info "Installing j4-make-config"
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
            chown "$USER" "files/i3/themes/$file"
            chgrp "$USER" "files/i3/themes/$file"
        done
        sudo -u "$USER" -H git add -u
        sudo -u "$USER" -H git commit -m "Updated j4-make-config themes"
        sudo -u "$USER" -H git push

        rm -rf "/tmp/downloaded"
    fi
fi

if $FILES; then
    # Download git shell prompt
    curl "https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh" -o "$HOME/.git_prompt.sh"

    # Download git autocompletion
    curl "https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash" -o "$HOME/.git-completion.bash"

    install_files `pwd`/files/"$FILE_ROOT"
fi

# Update everything
if [[ -e "$HOME/.bashrc" ]]; then
    source "$HOME/.bashrc"
fi

if which "j4-make-config"; then
    sudo -u "$USER" -H touch "$HOME/.config/i3/config.local"
    j4-make-config -r -a config.local none
fi
