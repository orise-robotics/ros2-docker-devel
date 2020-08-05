#!/bin/env bash

function usage() {
    printf "Usage: $0 [ROS_DISTRO] t]\n"
    printf "Build test and devel images for the provided ROS_DISTRO\n\n"
    printf "Options:\n"
    printf "  -h|--help\t\t Shows this help message\n"

    exit 0
}

while [ -n "$1" ]; do
    case $1 in
    -h | --help) usage ;;
    -?*)
        echo "Unknown option '$1'" 1>&2
        exit 1
        ;;
    *)
        break
        ;;
    esac
    shift
done

ROS_DISTRO=${1-noetic}
UBUNTU_DISTRO=""

case $ROS_DISTRO in
noetic) UBUNTU_DISTRO="focal" ;;
melodic) UBUNTU_DISTRO="bionic" ;;
kinetic) UBUNTU_DISTRO="xenial" ;;
*)
    echo "Not supported ROS_DISTRO '$ROS_DISTRO'" 1>&2
    exit 1
    ;;
esac

docker build --build-arg UBUNTU_DISTRO=$UBUNTU_DISTRO --target test-build -t ros-$ROS_DISTRO:test .
docker build --build-arg UBUNTU_DISTRO=$UBUNTU_DISTRO --build-arg ROS_DISTRO=$ROS_DISTRO --target devel-build -t ros-$ROS_DISTRO:devel .
