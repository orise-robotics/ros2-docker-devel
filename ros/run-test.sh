#!/bin/env bash

function usage() {
    printf "Usage: $0 [options] [PACKAGE.] t]\n"
    printf "Build test and devel images for the provided ROS_DISTRO\n\n"
    printf "Options:\n"
    printf "  -h|--help\t\t Shows this help message\n"
    printf "  -c|--clear-cache\t\t Clear apt-get persistent volume"
    printf "  -d|--distro\t\t Ubuntu distro (look for 'ros-DISTRO:test' image) [default=noetic]\n"
    printf "  -s|--source\t\t Vcstool .repos file [default = 'src.repos'\n"

    exit 0
}

SRC_REPOS="src.repos"
PACKAGES=""
ROS_DISTRO="noetic"

while [ -n "$1" ]; do
    case $1 in
    -h | --help) usage ;;
    -d | --distro)
        ROS_DISTRO = $2
        shift
        ;;
    -s | --source)
        SRC_REPOS = $2
        shift
        ;;
    -?*)
        echo "Unknown option '$1'" 1>&2
        exit 1
        ;;
    *)
        PACKAGES=$1
        break
        ;;
    esac
    shift
done

echo $PACKAGES
CONTAINER="ros-$ROS_DISTRO:test"

docker run -it \
    --env ROS_DISTRO=$ROS_DISTRO \
    --volume $(realpath $SRC_REPOS):/root/src.repos \
    $CONTAINER \
    test_entrypoint.sh $PACKAGES # entrypoint arguments
