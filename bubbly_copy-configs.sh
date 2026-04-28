#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
sudo rsync -avh "$SCRIPT_DIR/nginx-config/" /etc/nginx/
