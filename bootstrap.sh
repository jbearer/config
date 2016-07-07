# Install git so we can get the rest of this repo
if ! apt-get install git; then
    echo "Unable to install git. The config repo cannot be installed."
    exit 1
fi

if ! git clone https://github.com/jbearer/config.git ~/config; then
    echo "Unable to clone config repo. Installation unsuccessful."
    exit 1
fi

cd ~/config
. install.sh "$@"