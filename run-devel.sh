#!/usr/bin/env bash

usage() {
    printf "Usage: $0 [options]\n"
    printf "Run development container for the provided ROS_DISTRO\n\n"
    printf "Options:\n"
    printf "  -h|--help\t\t Shows this help message\n"
    printf "  -d|--distro\t\t ROS distro [default=noetic]\n"

    exit 0
}

. .env  # set initial values

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

VOLUME="${VOLUMES_FOLDER}/$CONTAINER_NAME"

if [ ! -d "${VOLUME}" ]; then
    mkdir -p "${VOLUME}"
fi

ROS_DISTRO=$ROS_DISTRO \
COLCON_WORKSPACE_FOLDER=$COLCON_WORKSPACE_FOLDER \
VOLUMES_FOLDER=$VOLUMES_FOLDER \
CONTAINER_NAME=$CONTAINER_NAME \
DOCKER_USER=$DOCKER_USER \
docker-compose up -d devel

docker exec -ti --user $DOCKER_USER $CONTAINER_NAME /bin/bash

docker-compose stop devel
