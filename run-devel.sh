#!/bin/env bash

function usage() {
    printf "Usage: $0 [options]\n"
    printf "Build test and devel images for the provided ROS_DISTRO\n\n"
    printf "Options:\n"
    printf "  -h|--help\t\t Shows this help message\n"
    printf "  -d|--distro\t\t ROS distro (look for 'ros-DISTRO:devel' image) [default=noetic]\n"

    exit 0
}

ROS_DISTRO="noetic"

while [ -n "$1" ]; do
    case $1 in
    -h | --help) usage ;;
    -d | --distro)
        ROS_DISTRO=$2
        shift
        ;;
    -?*)
        echo "Unknown option '$1'" 1>&2
        exit 1
        ;;
    *)
        echo "The script does not expect any argument" 1>&2
        exit 1
        ;;
    esac
    shift
done

CONTAINER="ros-$ROS_DISTRO-devel"
IMAGE="ros-$ROS_DISTRO:devel"

VOLUMES_FOLDER=$HOME/dev_ws/volumes/$CONTAINER

if [ ! -d "${VOLUMES_FOLDER}" ]; then
    mkdir -p "${VOLUMES_FOLDER}"
fi

if [ ! "$(docker ps -q -f name=$CONTAINER)" ]; then
    if [ ! "$(docker ps -aq -f status=exited -f name=$CONTAINER)" ]; then
        docker create -it \
            --net host \
            --volume="${VOLUMES_FOLDER}:/home/$USER:rw" \
            --volume="/etc/localtime:/etc/localtime:ro" \
            --user=$(id -u $USER):$(id -g $USER) \
            --env="DISPLAY" \
            --volume="/home/$USER/.ssh/known_hosts:/home/$USER/.ssh/known_hosts:rw" \
            --volume="/home/$USER/.ssh/id_rsa:/home/$USER/.ssh/id_rsa:ro" \
            --volume="/home/$USER/.ssh/id_rsa.pub:/home/$USER/.ssh/id_rsa.pub:ro" \
            --volume="/home/$USER/.gitconfig:/etc/gitconfig:ro" \
            --volume="/etc/group:/etc/group:ro" \
            --volume="/etc/passwd:/etc/passwd:ro" \
            --volume="/etc/shadow:/etc/shadow:ro" \
            --volume="/etc/sudoers.d:/etc/sudoers.d:ro" \
            --volume="/tmp/.X11-unix:/tmp/.X11-unix:rw" \
            --privileged \
            --gpus 'all,"capabilities=utility,graphics,compute"' \
            --workdir="/home/$USER" \
            --name $CONTAINER \
            $IMAGE
    fi
    docker start -ai $CONTAINER
else
    docker exec -ti $CONTAINER /bin/bash
fi
