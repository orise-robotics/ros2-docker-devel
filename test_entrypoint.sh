#!/bin/env bash

PACKAGE=$1

export DEBIAN_FRONTEND=noninteractive
apt-get update

rosdep init && rosdep update

mkdir -p src/

echo "<<<<<<<<<<<<<<<<<<<$PACKAGE>>>>>>>>>>>>>>>>"
echo "<<<$PACKAGE: VCS IMPORT>>>"
vcs import --input src.repos src/

echo "<<<$PACKAGE: ROSDEP INSTALL>>>"
rosdep install --rosdistro="$ROS_DISTRO" -y -i -r --from-paths "src/$PACKAGE"

# shellcheck source=/dev/null
source /opt/ros/"$ROS_DISTRO"/setup.bash

echo "<<<$PACKAGE: BUILD>>>"
colcon build --packages-up-to "$(basename "$PACKAGE")"

# shellcheck source=/dev/null
source install/local_setup.sh

echo "<<<$PACKAGE: TEST>>>"
colcon test --packages-select "$(basename "$PACKAGE")"

colcon test-result --verbose

exec /bin/bash
