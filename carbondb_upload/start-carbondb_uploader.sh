#!/bin/bash
set -euo pipefail

if ! command -v python3 &> /dev/null; then
    echo "Python 3 is not installed. Installing Python 3..."
    sudo apt-get update
    sudo apt-get install -y python3
fi


SCRIPT_DIR=$(realpath $(dirname "$0"))
CDB_HOME="/usr/local/bin/carbondb_upload"

CMD="python3 $CDB_HOME/carbondb_uploader.py"

eval $CMD
