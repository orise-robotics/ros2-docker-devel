#!/usr/bin/env bash

usage() {
    printf "Usage: $0 [options]\n"
    printf "Run development container for the provided ROS_DISTRO\n\n"
    printf "Options:\n"
    printf "  -h|--help\t\t Shows this help message\n"
    printf "  -d|--distro\t\t ROS distro [default=noetic]\n"

    exit 0
}

. .config  # set initial values

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

CONTAINER="orise-$ROS_DISTRO-devel"
IMAGE="oriserobotics/ros-$ROS_DISTRO:devel"

VOLUME="${VOLUMES_FOLDER}/$CONTAINER"

if [ ! -d "${VOLUME}" ]; then
    mkdir -p "${VOLUME}"
fi

if [ ! "$(docker ps -q -f name=$CONTAINER)" ]; then
    if [ ! "$(docker ps -aq -f status=exited -f name=$CONTAINER)" ]; then
        docker create -it \
            --net host \
            --volume="${VOLUME}:/home/$USER:rw" \
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
