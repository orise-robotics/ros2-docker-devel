#!/usr/bin/env bash

usage() {
  printf "Usage: %s [options]\n" "$0"
  printf "Build and run the development container\n\n"
  printf "Options:\n"
  printf "  -b|--build\t\t Force image build\n"
  printf "  -d|--distro ROS_DISTRO ROS distribution to base on (e.g. 'focal', 'galactic', ...)\n"
  printf "  -h|--help\t\t Shows this help message\n"
  printf "  -u|--user\t\t User name in the devel container\n"
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
  -u | --user)
    CONTAINER_USER=$2
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

CONTAINER_NAME="$CONTAINER_USER-$ROS_DISTRO-devel"
COLCON_WORKSPACE_FOLDER="/home/$CONTAINER_USER"

VOLUME="${VOLUMES_FOLDER}/$CONTAINER_NAME"

if [ ! -d "${VOLUME}" ]; then
  mkdir -p "${VOLUME}"
fi

# shellcheck disable=SC2097,SC2098
ROS_DISTRO=$ROS_DISTRO \
  VOLUMES_FOLDER=$VOLUMES_FOLDER \
  COLCON_WORKSPACE_FOLDER=$COLCON_WORKSPACE_FOLDER \
  CONTAINER_NAME=$CONTAINER_NAME \
  CONTAINER_USER=$CONTAINER_USER \
  SSH_AUTH_SOCK_HOST_PATH="$SSH_AUTH_SOCK" \
  SSH_AUTH_SOCK_CONTAINER_PATH="/home/$CONTAINER_USER/.ssh-agent/ssh-agent.sock" \
  docker-compose -p "$ROS_DISTRO" --env-file .env up $BUILD_IMAGE_OPT -d devel

test $XDISPLAY && xhost +local:root >/dev/null 2>&1
docker exec -ti --user orise "$CONTAINER_NAME" /bin/bash
test $XDISPLAY && xhost -local:root >/dev/null 2>&1

docker-compose stop devel
