#!/usr/bin/env bash

filetype()
{
    ftype="<unknown file type>"
    if [[ -f "$1" ]]; then
        ftype="file"
    elif [[ -d "$1" ]]; then
        ftype="directory"
    fi
    echo "$ftype"
}

remove_opt()
{
    if [[ -e "$1" ]]; then
        ftype=`filetype "$1"`

        if ! $FORCE; then
            echo -n "Overwrite existing $ftype $1? "
            read -n 1 response
            echo "" # Newline
            if [[ "$response" != "y" ]]; then
                return 1
            fi
        fi

        echo "Removing existing $ftype $1"
        rm -rf "$1"
    fi
}

overwrite_opt()
{
    if ! remove_opt "$2"; then
        return 1
    fi

    ftype=`filetype "$1"`
    echo "Installing $ftype $2 from $1"
    mkdir --parents `dirname $2`
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

FORCE=false
PACKAGES=false
FILES=false

for opt in $@; do
    case "$opt" in
        "-f"|"--force" )
            FORCE=true
            ;;
        "packages" )
            PACKAGES=true
            ;;
        "files" )
            FILES=true
            ;;
        * )
            echo "Invalid option $opt"
            exit 1
            ;;
    esac
done

if ! $PACKAGES && ! $FILES; then
    # Default to installing everything
    PACKAGES=true
    FILES=true
fi

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
        mv "/tmp/downloaded/$root/j4-make-config" "/usr/bin"
        mv "/tmp/downloaded/$root/themes" "files/i3"
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
    touch "$HOME/.config/i3/config.local"
    j4-make-config -a "$HOME/.config/i3/config.local" -r none
fi
