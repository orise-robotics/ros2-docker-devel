#!/bin/env bash

function usage() {
    printf "Usage: $0 [options] [PACKAGE]\n"
    printf "Build test and devel images for the provided ROS_DISTRO\n\n"
    printf "Options:\n"
    printf "  -h|--help\t\t Shows this help message\n"
    printf "  -c|--clear-cache\t\t Clear apt-get persistent volume"
    printf "  -d|--distro\t\t ROS distro (look for 'ros-DISTRO:test' image) [default=noetic]\n"
    printf "  -s|--source\t\t VCStool .repos file [default = 'src.repos']\n"

    exit 0
}

SRC_REPOS="src.repos"
PACKAGE=""
ROS_DISTRO="noetic"

while [ -n "$1" ]; do
    case $1 in
    -h | --help) usage ;;
    -d | --distro)
        ROS_DISTRO=$2
        shift
        ;;
    -s | --source)
        SRC_REPOS=$2
        shift
        ;;
    -?*)
        echo "Unknown option '$1'" 1>&2
        exit 1
        ;;
    *)
        PACKAGE=$1
        break
        ;;
    esac
    shift
done

CONTAINER="orise-$ROS_DISTRO-test"
IMAGE="oriserobotics/$ROS_DISTRO:test"
UBUNTU_DISTRO=$(lsb_release -cs)

if [ "docker ps -q -f name=$CONTAINER -f status=exited" ]; then
    docker container rm $CONTAINER
fi

docker run -it \
    --env ROS_DISTRO=$ROS_DISTRO \
    --volume $(realpath $SRC_REPOS):/root/src.repos \
    --volume="${UBUNTU_DISTRO}_apt_cache:/var/cache/apt/archives" \
    --gpus 'all,"capabilities=utility,graphics,compute"' \
    --name="ros-$ROS_DISTRO-test" \
    $IMAGE \
    test_entrypoint.sh $PACKAGE # entrypoint arguments

# TODO: work for multiple packages, volume apt-update, rosdep, source and builds

# docker volume rm "${UBUNTU_DISTRO}_apt_cache" > /dev/null 2>&1
