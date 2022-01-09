#!/usr/bin/env bash

usage() {
  printf "Usage: %s [options]\n" "$0"
  printf "Build and run the development container\n\n"
  printf "Options:\n"
  printf "  -b|--build\t\t Force image build\n"
  printf "  -c|--container\t\t Container name (default: '\$CONTAINER_USER-\$ROS_DISTRO-devel')\n"
  printf "  -d|--distro ROS_DISTRO ROS distribution to base on (default: 'focal')\n"
  printf "  -h|--help\t\t Shows this help message\n"
  printf "  -p|--project\t\t Define the project name (default: '\$CONTAINER_NAME')\n"
  printf "  -u|--user\t\t User name in the devel container (default: 'orise')\n"
  printf "  -x|--display\t\t Enable X display. It allows running graphic tools within the container\n"

  exit 0
}

# Load configuration (environment varibles)
# shellcheck source=/dev/null
source .env

# default values
ROS_DISTRO=${ROS_DISTRO:="foxy"}
CONTAINER_USER=${CONTAINER_USER:="orise"}
CONTAINER_NAME=${CONTAINER_NAME:="$CONTAINER_USER-$ROS_DISTRO-devel"}
COLCON_WORKSPACE_FOLDER=${COLCON_WORKSPACE_FOLDER:="/home/$CONTAINER_USER"}
PROJECT_NAME=${PROJECT_NAME:="$CONTAINER_NAME"}

BUILD_IMAGE_OPT=''

while [ -n "$1" ]; do
  case $1 in
  -b | --build)
    BUILD_IMAGE_OPT="--build"
    ;;
  -h | --help) usage ;;
  -c | --container)
    CONTAINER_NAME=$2
    shift
    ;;
  -d | --distro)
    ROS_DISTRO=$2
    shift
    ;;
  -p | --project)
    PROJECT_NAME=$2
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
  docker-compose \
  -p "$PROJECT_NAME" \
  -f docker-compose.yml \
  -f compose-add-ons/nvidia-gpu.yml \
  -f compose-add-ons/ssh-forwarding.yml \
  --env-file .env \
  up $BUILD_IMAGE_OPT -d devel

test $XDISPLAY && xhost +local:root >/dev/null 2>&1
docker-compose -p "$PROJECT_NAME" exec --user "$CONTAINER_USER" devel /bin/bash
test $XDISPLAY && xhost -local:root >/dev/null 2>&1

if [ -z "$(docker inspect "$CONTAINER_NAME" --format='{{join .ExecIDs ""}}')" ]; then
  docker-compose -p "$PROJECT_NAME" stop devel
fi
