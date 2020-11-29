#!/usr/bin/env bash

set -e

find . \! -user orise -exec chown orise '{}' +

source "/opt/ros/$ROS_DISTRO/setup.bash"

exec gosu orise "$@"
