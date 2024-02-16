#!/bin/bash
set -euo pipefail

THIS_SCRIPT_DIR=$(realpath $(dirname "$0"))
CDB_HOME="/usr/local/bin/carbondb_upload"
CONF_FILE="/etc/carbondb_uploader.conf"

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

if ! command -v python3 &> /dev/null; then
    echo "Python 3 is not installed. Installing Python 3..."
    apt install -y python3
fi

mkdir -p $CDB_HOME

cd $THIS_SCRIPT_DIR

cp start-carbondb_uploader.sh $CDB_HOME
chmod a+x "$CDB_HOME/start-carbondb_uploader.sh"

cp carbondb_uploader.py $CDB_HOME
chmod a+x "$CDB_HOME/carbondb_uploader.py"

cp carbondb_uploader.service /etc/systemd/system/carbondb_uploader.service
chmod 644 /etc/systemd/system/carbondb_uploader.service

cp carbondb_uploader.timer /etc/systemd/system/carbondb_uploader.timer
chmod 644 /etc/systemd/system/carbondb_uploader.timer


if [ ! -f "$CONF_FILE" ]; then
    cp carbondb_uploader.conf "$CONF_FILE"
    UUID=$(uuidgen)
    sed -i "s/<ADD_ID_HERE>/$UUID/" "$CONF_FILE"
    echo "---------------------------------------------------------"
    echo "Your machine id is: $UUID"
    echo "---------------------------------------------------------"

else
    echo "Configuration file $conf_file already exists. You will need to update it manually"
fi


if systemctl is-active --quiet carbondb_uploader.timer; then
    systemctl restart carbondb_uploader.timer
    echo "carbondb_uploader.timer reloaded"
else
    systemctl start carbondb_uploader.timer
    systemctl enable carbondb_uploader.timer
fi

echo "!!! Install complete !!!"