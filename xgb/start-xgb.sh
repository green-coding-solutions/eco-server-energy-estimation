#!/bin/bash
set -euo pipefail

if ! command -v python3 &> /dev/null; then
    echo "Python 3 is not installed. Installing Python 3..."
    sudo apt-get update
    sudo apt-get install -y python3
fi


SCRIPT_DIR=$(realpath $(dirname "$0"))
XGB_HOME="/usr/local/bin/xgb"
MODEL_DIR="$XGB_HOME/spec-power-model"
CONFIG_FILE="/etc/xgb.conf"

source "$MODEL_DIR/venv/bin/activate"

CMD="python3 $MODEL_DIR/xgb.py"
while IFS='=' read -r key value; do
    if [[ $key == \#* ]]; then
        continue
    fi
    CMD="$CMD --$key $value"
done < "$CONFIG_FILE"

eval $CMD --autoinput --energy --silent
