partial=false
branch=master

while [ "$1" != "--" ] && [ "$#" != "0" ]; do
    case "$1" in
        "-p"|"--partial" )
            partial=true
            ;;
        "-b"|"--branch" )
            if [ "$#" == 1 ]; then
                echo 2>&1 "--branch requires argument"
                exit 1
            fi
            case "$2" in
                -* )
                    echo 2>&1 "--branch requires argument"
                    exit 1
                    ;;
                * )
                    branch="$2"
                    shift
                    ;;
            esac
            ;;
    esac

    shift
done

if [ "$1" == "--" ]; then
    shift
fi

# Install git so we can get the rest of this repo
if ! sudo apt-get -y install git; then
    echo "Unable to install git. The config repo cannot be installed."
    exit 1
fi

if ! git clone https://github.com/jbearer/config.git ~/config; then
    echo "Unable to clone config repo. Installation unsuccessful."
    exit 1
fi

(cd ~/config; git checkout "$branch")

if ! $partial; then
    cd ~/config
    sudo ./install.sh "$@"
fi
