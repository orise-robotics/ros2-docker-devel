#!/usr/bin/env bash

usage() {
  printf "Usage: %s [options]\n" "$0"
  printf "Build and run the development container\n\n"
  printf "Options:\n"
  printf "  -b, --build                       Force image build\n"
  printf "  -d, --distro ROS_DISTRO           ROS distribution to base on (default: 'focal')\n"
  printf "  -h, --help                        Shows this help message\n"
  printf "  -p, --project PROJECT             Define the project name (default: '\$CONTAINER_USER-\$ROS_DISTRO-devel')\n"
  printf "  -u, --user USER                   User name in the devel container (default: 'orise')\n"
  printf "  -v, --volume-base-folder FOLDER   Define the base folder for bind mounting the container's home folder (default: create a named volume based on the project name).\n"
  printf "  -x, --display                     Enable X display. It allows running graphic tools within the container\n"
  # printf "  -g|--gpu                 Enable nvidia GPU in the container (require nvidia-container-runtime)\n"
  # printf "  -s|--ssh-forwarding      Enable SSH forwarding (bind the ssh-agent socket defined in \$SSH_AUTH_SOCK)\n"

  exit 0
}

# Load configuration (environment varibles)
# shellcheck source=/dev/null
source .env

# default values
ROS_DISTRO=${ROS_DISTRO:-"foxy"}
CONTAINER_USER=${CONTAINER_USER:-"orise"}
VOLUME_BASE_FOLDER=${VOLUME_BASE_FOLDER:-}

BUILD_IMAGE_OPT=''
COMPOSE_ADD_ONS=(
  'ssh-forwarding'
  'nvidia-gpu'
)

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
  -p | --project)
    PROJECT_NAME=$2
    shift
    ;;
  -u | --user)
    CONTAINER_USER=$2
    shift
    ;;
  -v | --volume-base-folder)
    VOLUME_BASE_FOLDER=$2
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

# derived default values
COLCON_WORKSPACE_FOLDER=${COLCON_WORKSPACE_FOLDER:-"/home/$CONTAINER_USER"}
PROJECT_NAME=${PROJECT_NAME:-"$CONTAINER_USER-$ROS_DISTRO-devel"}

# configure home volume binding
HOME_VOLUME_FOLDER=$VOLUME_BASE_FOLDER/$PROJECT_NAME
if [ -n "$VOLUME_BASE_FOLDER" ];then
  # create folder if it doesn't exist
  if [ ! -d "${HOME_VOLUME_FOLDER}" ]; then
    mkdir -p "${HOME_VOLUME_FOLDER}"
  fi
  COMPOSE_ADD_ONS+=("bind-home-volume")
fi

# Build compose add-ons options
if [ -n "${COMPOSE_ADD_ONS[*]}" ]; then
  COMPOSE_ADD_ONS_OPT=( "${COMPOSE_ADD_ONS[@]/#/-f\ .\/compose-add-ons\/}" )
  COMPOSE_ADD_ONS_OPT=( "${COMPOSE_ADD_ONS_OPT[@]/%/.yml}" )
fi

# shellcheck disable=SC2097,SC2098,SC2068
ROS_DISTRO=$ROS_DISTRO \
  COLCON_WORKSPACE_FOLDER=$COLCON_WORKSPACE_FOLDER \
  CONTAINER_USER=$CONTAINER_USER \
  HOME_VOLUME_FOLDER=$HOME_VOLUME_FOLDER \
  SSH_AUTH_SOCK_HOST_PATH="$SSH_AUTH_SOCK" \
  SSH_AUTH_SOCK_CONTAINER_PATH="/home/$CONTAINER_USER/.ssh-agent/ssh-agent.sock" \
  docker-compose \
  -p "$PROJECT_NAME" \
  -f docker-compose.yml \
  ${COMPOSE_ADD_ONS_OPT[@]} \
  --env-file .env \
  up $BUILD_IMAGE_OPT -d devel

test $XDISPLAY && xhost +local:root >/dev/null 2>&1
docker-compose -p "$PROJECT_NAME" exec --user "$CONTAINER_USER" devel /bin/bash
test $XDISPLAY && xhost -local:root >/dev/null 2>&1

CONTAINER_ID=$(docker-compose -p "$PROJECT_NAME" ps -q devel)
if [ -z "$(docker inspect "$CONTAINER_ID" --format='{{join .ExecIDs ""}}')" ]; then
  docker-compose -p "$PROJECT_NAME" stop devel
fi
