#!/usr/bin/env bash

usage() {
  printf "Usage: %s [options]\n" "$0"
  printf "Build and run the development container\n\n"
  printf "Options:\n"
  printf "  -b, --build                       Build image (with cache enabled)\n"
  printf "  -d, --distro ROS_DISTRO           ROS distribution to base on (default: 'focal')\n"
  printf "  -f, --force-build                 Force image build (disable cache)\n"
  printf "  -g, --gpu                         Enable nvidia GPU in the container (require nvidia-container-runtime)\n"
  printf "  -h, --help                        Shows this help message\n"
  printf "  -p, --project PROJECT             Define the project name (default: '\$CONTAINER_USER-\$ROS_DISTRO-devel')\n"
  printf "  -s, --ssh-forwarding              Enable SSH forwarding (bind the ssh-agent socket defined in \$SSH_AUTH_SOCK)\n"
  printf "  -u, --user USER                   User name in the devel container (default: 'orise')\n"
  printf "  -v, --volume-base-folder FOLDER   Define the base folder for bind mounting the container's home folder (default: create a named volume based on the project name).\n"
  printf "  -x, --xdisplay                    Enable X display. It allows running graphic tools within the container\n"

  printf "\n\nEnvironment Variables (CLI option):\n"
  printf "  BUILD_IMAGE           (-b, --build)\n"
  printf "  CONTAINER_USER        (-u, --user)\n"
  printf "  ENABLE_NVIDIA_GPU     (-g, --gpu)\n"
  printf "  ENABLE_SSH_FORWARDING (-s, --ssh-forwarding)\n"
  printf "  FORCE_BUILD_IMAGE     (-f, --force-build)\n"
  printf "  PROJECT_NAME          (-p, --project)\n"
  printf "  ROS_DISTRO            (-d, --distro)\n"
  printf "  VOLUME_BASE_FOLDER    (-v, --volume-base-folder)\n"
  printf "  XDISPLAY              (-x, --xdisplay)\n"

  exit 0
}

# Load configuration (environment varibles)
# shellcheck source=/dev/null
source .env

# default values
ROS_DISTRO=${ROS_DISTRO:-"foxy"}
CONTAINER_USER=${CONTAINER_USER:-"orise"}
VOLUME_BASE_FOLDER=${VOLUME_BASE_FOLDER:-}

BUILD_IMAGE=
FORCE_BUILD_IMAGE=
COMPOSE_ADD_ONS=()

while [ -n "$1" ]; do
  case $1 in
  -b | --build) BUILD_IMAGE=1 ;;
  -d | --distro)
    ROS_DISTRO=$2
    shift
    ;;
  -h | --help) usage ;;
  -f | --force-build)
    BUILD_IMAGE=1
    FORCE_BUILD_IMAGE=1
    ;;
  -g | --gpu) ENABLE_NVIDIA_GPU=1 ;;
  -p | --project)
    PROJECT_NAME=$2
    shift
    ;;
  -s | --ssh-agent-forwarding) ENABLE_SSH_FORWARDING=1 ;;
  -u | --user)
    BUILD_IMAGE=1
    CONTAINER_USER=$2
    shift
    ;;
  -v | --volume-base-folder)
    VOLUME_BASE_FOLDER=$2
    shift
    ;;
  -x | --xdisplay)
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

# derived default values
COLCON_WORKSPACE_FOLDER=${COLCON_WORKSPACE_FOLDER:-"/home/$CONTAINER_USER"}
PROJECT_NAME=${PROJECT_NAME:-"$CONTAINER_USER-$ROS_DISTRO-devel"}

# Compose add-ons
if [ $ENABLE_NVIDIA_GPU ]; then COMPOSE_ADD_ONS+=("nvidia-gpu"); fi
if [ $ENABLE_SSH_FORWARDING ]; then COMPOSE_ADD_ONS+=("ssh-forwarding"); fi

# configure home volume binding
HOME_VOLUME_FOLDER=$VOLUME_BASE_FOLDER/$PROJECT_NAME
if [ -n "$VOLUME_BASE_FOLDER" ]; then
  # create folder if it doesn't exist
  if [ ! -d "${HOME_VOLUME_FOLDER}" ]; then
    mkdir -p "${HOME_VOLUME_FOLDER}"
  fi
  COMPOSE_ADD_ONS+=("bind-home-volume")
fi

# Set compose add-ons options
if [ -n "${COMPOSE_ADD_ONS[*]}" ]; then
  COMPOSE_ADD_ONS_OPT=("${COMPOSE_ADD_ONS[@]/#/-f\ .\/compose-add-ons\/}")
  COMPOSE_ADD_ONS_OPT=("${COMPOSE_ADD_ONS_OPT[@]/%/.yml}")
fi

# Build image
if [ "$BUILD_IMAGE" ]; then
  NO_CACHE_OPT=${FORCE_BUILD_IMAGE:+"--no-cache"}
  COLCON_WORKSPACE_FOLDER=$COLCON_WORKSPACE_FOLDER \
    docker-compose build $NO_CACHE_OPT \
    --build-arg ROS_DISTRO="$ROS_DISTRO" \
    --build-arg CONTAINER_USER="$CONTAINER_USER" \
    --build-arg USER_UID="$(id -u "$USER")" \
    --build-arg USER_GID="$(id -g "$USER")" \
    devel
fi

# shellcheck disable=SC2097,SC2098,SC2068
ROS_DISTRO=$ROS_DISTRO \
  COLCON_WORKSPACE_FOLDER=$COLCON_WORKSPACE_FOLDER \
  CONTAINER_USER=$CONTAINER_USER \
  HOME_VOLUME_FOLDER=$HOME_VOLUME_FOLDER \
  SSH_AUTH_SOCK_HOST_PATH="$SSH_AUTH_SOCK" \
  SSH_AUTH_SOCK_CONTAINER_PATH="/home/$CONTAINER_USER/.ssh-agent/ssh-agent.sock" \
  USER_UID=$(id -u "$USER") \
  USER_GID=$(id -g "$USER") \
  docker-compose \
  -p "$PROJECT_NAME" \
  -f docker-compose.yml \
  ${COMPOSE_ADD_ONS_OPT[@]} \
  --env-file .env \
  up -d devel

# Check if the service is running
if docker-compose -p "$PROJECT_NAME" ps --services --filter status=stopped | grep -x -q devel; then
  echo "Failed to run devel service. Try running run-devel.sh with -b option."
  exit 1
fi

test $XDISPLAY && xhost +local:root >/dev/null 2>&1
docker-compose -p "$PROJECT_NAME" exec --user "$CONTAINER_USER" devel /bin/bash
test $XDISPLAY && xhost -local:root >/dev/null 2>&1

CONTAINER_ID=$(docker-compose -p "$PROJECT_NAME" ps -q devel)
if [ -z "$(docker inspect "$CONTAINER_ID" --format='{{join .ExecIDs ""}}')" ]; then
  docker-compose -p "$PROJECT_NAME" stop devel
fi
