SRC_REPO=$1
PACKAGE=$2

mkdir src/
vcs import --input $SRC_REPO src/

rosdep install --from-paths src/$PACKAGE
source /opt/ros/noetic/setup.bash

colcon build --packages-select $PACKAGE

source install/local_setup.sh

colcon test --packages-select $PACKAGE
colcon test-result
