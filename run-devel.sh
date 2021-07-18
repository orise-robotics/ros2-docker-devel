#!/usr/bin/env bash

usage() {
  printf "Usage: %s [options]\n" "$0"
  printf "Run development container given the .env configuration\n\n"
  printf "Options:\n"
  printf "  -b|--build\t\t Force image build\n"
  printf "  -d|--distro ROS_DISTRO Override target ROS distro in .env file\n"
  printf "  -h|--help\t\t Shows this help message\n"
  printf "  -x|--display\t\t Enable X display. It allows running graphic tools within the container\n"

  exit 0
}

# shellcheck source=/dev/null
source .env # set initial values

BUILD_IMAGE_OPT=''

while [ -n "$1" ]; do
  case $1 in
  -b | --build)
    BUILD_IMAGE_OPT="--build"
    ;;
  -h | --help) usage ;;
  -d | --distro)
    ROS_DISTRO=$2
    shift
    ;;
  -x | --display)
    XDISPLAY=1
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

CONTAINER_NAME="orise-$ROS_DISTRO-devel"

VOLUME="${VOLUMES_FOLDER}/$CONTAINER_NAME"

if [ ! -d "${VOLUME}" ]; then
  mkdir -p "${VOLUME}"
fi

# shellcheck disable=SC2097,SC2098
ROS_DISTRO=$ROS_DISTRO \
  VOLUMES_FOLDER=$VOLUMES_FOLDER \
  CONTAINER_NAME=$CONTAINER_NAME \
  docker-compose -p "$ROS_DISTRO" --env-file .env up $BUILD_IMAGE_OPT -d devel

test $XDISPLAY && xhost +local:root >/dev/null 2>&1
docker exec -ti --user orise "$CONTAINER_NAME" /bin/bash
test $XDISPLAY && xhost -local:root >/dev/null 2>&1

docker-compose stop devel
