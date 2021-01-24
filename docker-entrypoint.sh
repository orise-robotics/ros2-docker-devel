#!/usr/bin/env bash

set -e

find . \! -user orise -exec chown orise '{}' +

# shellcheck source=/dev/null
source "/opt/ros/$ROS_DISTRO/setup.bash"

[ ! -e /home/orise/.bashrc ] && cp /etc/skel/.bashrc /home/orise/.bashrc

exec gosu orise "$@"
