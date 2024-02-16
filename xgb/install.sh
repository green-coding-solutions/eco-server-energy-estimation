#!/bin/bash
set -euo pipefail

THIS_SCRIPT_DIR=$(realpath $(dirname "$0"))
XGB_HOME="/usr/local/bin/xgb"
MODEL_DIR="$XGB_HOME/spec-power-model"

if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" >&2
    exit 1
fi

if [ -f /etc/os-release ]; then
    . /etc/os-release

    if [ "$ID" != "debian" ] && [ "$ID" != "ubuntu" ]; then
        echo "This script is intended to run on Debian or Ubuntu machines only" >&2
        exit 1
    fi
else
    echo "This script requires the /etc/os-release file, which is not found" >&2
    exit 1
fi

apt update

if ! command -v git &> /dev/null
then
    echo "Git is not installed. Installing Git..."
    apt install -y git
fi

if ! command -v python3 &> /dev/null; then
    echo "Python 3 is not installed. Installing Python 3..."
    apt install -y python3
fi

if ! dpkg -l | grep -qw python3-venv; then
    echo "The package python3-venv is not installed. Installing..."
    apt install -y python3-venv
fi

mkdir -p $XGB_HOME

if [ -d "$MODEL_DIR" ]; then
    echo "The directory $MODEL_DIR already exists. Assuming update."
else
    echo "Cloning repository into $MODEL_DIR..."
    git clone "https://github.com/green-coding-solutions/spec-power-model.git" "$MODEL_DIR"
fi

cd $MODEL_DIR
git pull

if [ ! -d "$MODEL_DIR/venv" ]; then
    echo "Creating a virtual environment..."
    python3 -m venv "$MODEL_DIR/venv"
fi

source "$MODEL_DIR/venv/bin/activate"

pip install -r requirements.txt

cd $THIS_SCRIPT_DIR
cp start-xgb.sh $XGB_HOME
chmod a+x "$XGB_HOME/start-xgb.sh"

cp xgb.service /etc/systemd/system/xgb.service
chmod 644 /etc/systemd/system/xgb.service

cp xgb.conf /etc/xgb.conf

if systemctl is-active --quiet xgb.service; then
    systemctl restart xgb.service
    systemctl daemon-reload
    echo "xgb.service reloaded"
else
    systemctl start xgb.service
    systemctl enable  xgb.service
fi

echo "!!! Install complete !!!"