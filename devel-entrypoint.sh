#!/usr/bin/env bash

set -e

[ ! -f "$HOME/.basrhc" ] && cp /etc/skel/.bashrc "$HOME"

exec "$@"
