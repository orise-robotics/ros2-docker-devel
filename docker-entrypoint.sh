#!/usr/bin/env bash

set -e

find . \! -user "$USER" -exec chown "$USER" '{}' +

# shellcheck source=/dev/null
source "/opt/ros/$ROS_DISTRO/setup.bash"

[ ! -e "/home/$USER/.bashrc" ] && cp /etc/skel/.bashrc "/home/$USER/.bashrc"

exec gosu "$USER" "$@"
