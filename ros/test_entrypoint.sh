#!/bin/env bash

PACKAGE=$1

echo $PACKAGE

apt-get update

rosdep init && rosdep update

mkdir src/

vcs import --input src.repos src/

rosdep install -y --from-paths src/$PACKAGE
source /opt/ros/noetic/setup.bash

colcon build --packages-select $(basename $PACKAGE)

source install/local_setup.sh

colcon test --packages-select $(basename $PACKAGE)
colcon test-result
