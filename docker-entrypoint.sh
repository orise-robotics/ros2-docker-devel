#!/usr/bin/env bash

set -e

find . \! -user orise -exec chown orise '{}' +

# shellcheck source=/dev/null
source "/opt/ros/$ROS_DISTRO/setup.bash"

exec gosu orise "$@"
