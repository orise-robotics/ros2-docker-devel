#!/bin/env bash

PACKAGE=$1

echo $PACKAGE

export DEBIAN_FRONTEND=noninteractive
apt-get update

rosdep init && rosdep update

mkdir src/

echo "<<<<<<<<<<<<<<<<<<<$PACKAGE>>>>>>>>>>>>>>>>"
echo "<<<$PACKAGE: VCS IMPORT>>>"
vcs import --input src.repos src/

echo "<<<$PACKAGE: ROSDEP INSTALL>>>"
rosdep install --rosdistro=$ROS_DISTRO -y --from-paths src/$PACKAGE
source /opt/ros/noetic/setup.bash

echo "<<<$PACKAGE: BUILD>>>"
colcon build --packages-up-to $(basename $PACKAGE)

source install/local_setup.sh

echo "<<<$PACKAGE: TEST>>>"
colcon test --packages-select $(basename $PACKAGE)

colcon test-result
