#!/usr/bin/env bash

usage() {
  printf "Usage: %s [options]\n" "$0"
  printf "Build, create and run the development container.\n\n"
  printf "Options:\n"
  printf "  -b, --build                   Build image (with cache enabled)\n"
  printf "  -d, --distro ROS_DISTRO       Override the ROS distribution (default: 'focal')\n"
  printf "  -e, --exec \"EXEC_COMMAND\"   Override the command to execute in the container (default: '/bin/bash')\n"
  printf "  -f, --force-build             Force image build (disable cache)\n"
  printf "  -h, --help                    Shows this help message\n"
  printf "  -p, --prefix PROJECT_PREFIX   Override the project name prefix  (default: 'ros')\n"
  printf "  -r, --recreate                Recreates the container even if there was no changes in configuration\n"

  printf "\n\nEnvironment Variables:\n"
  printf "  CONTAINER_USER          User name in the devel container (default: '\$USER')\n"
  printf "  EXEC_COMMAND            Command to execute in the container (default: '/bin/bash')\n"
  printf "  ENABLE_NVIDIA_GPU       Enable nvidia GPU in the container (require nvidia-container-runtime)\n"
  printf "  ENABLE_SSH_FORWARDING   Enable SSH forwarding (bind the ssh-agent socket defined in \$SSH_AUTH_SOCK)\n"
  printf "  PROJECT_PREFIX          Define the project name prefix (default: 'ros')\n"
  printf "  ROS_DISTRO              ROS distribution to base on (default: 'focal')\n"
  printf "  VOLUME_BASE_FOLDER      Define the base folder for bind mounting the container's home folder (default: create a named volume based on the project name)\n"
  printf "  XDISPLAY                Enable X display. It allows running graphic tools within the container\n"

  printf "A container is uniquely identified by the project name defined as \${PROJECT_PREFIX}_\${ROS_DISTRO}"

  exit 0
}

# Load configuration (environment varibles)
# shellcheck source=/dev/null
source .env

# default values
ROS_DISTRO=${ROS_DISTRO:-"foxy"}
CONTAINER_USER=${CONTAINER_USER:-"$USER"}
PROJECT_PREFIX=${PROJECT_NAME:-"ros"}
VOLUME_BASE_FOLDER=${VOLUME_BASE_FOLDER:-}
EXEC_COMMAND=${EXEC_COMMAND:-"/bin/bash"}

BUILD_IMAGE=
FORCE_BUILD_IMAGE=
COMPOSE_ADD_ONS=()
COMPOSE_OPT_ARGS=()

while [ -n "$1" ]; do
  case $1 in
  -b | --build) BUILD_IMAGE=1 ;;
  -d | --distro)
    ROS_DISTRO=$2
    shift
    ;;
  -e | --exec)
    EXEC_COMMAND=$2
    shift
    ;;
  -h | --help) usage ;;
  -f | --force-build)
    BUILD_IMAGE=1
    FORCE_BUILD_IMAGE=1
    ;;
  -p | --prefix)
    PROJECT_PREFIX=$2
    shift
    ;;
  -r | --recreate) COMPOSE_OPT_ARGS+=("--force-recreate") ;;
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
PROJECT_NAME="${PROJECT_PREFIX}_${ROS_DISTRO}"

# Compose add-ons
if [ "$ENABLE_NVIDIA_GPU" ]; then COMPOSE_ADD_ONS+=("nvidia-gpu"); fi
if [ "$ENABLE_SSH_FORWARDING" ]; then COMPOSE_ADD_ONS+=("ssh-forwarding"); fi
if [ "$XDISPLAY" ]; then COMPOSE_ADD_ONS+=("xdisplay"); fi

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

USER_UID=$(id -u "$USER")
USER_GID=$(id -g "$USER")

# Build image
if [ "$BUILD_IMAGE" ]; then
  NO_CACHE_OPT=${FORCE_BUILD_IMAGE:+"--no-cache"}
  COLCON_WORKSPACE_FOLDER=$COLCON_WORKSPACE_FOLDER \
  USER_UID="$USER_UID" \
  USER_GID="$USER_GID" \
    docker-compose build $NO_CACHE_OPT \
    --build-arg ROS_DISTRO="$ROS_DISTRO" \
    devel
fi

# shellcheck disable=SC2097,SC2098,SC2068
ROS_DISTRO=$ROS_DISTRO \
  COLCON_WORKSPACE_FOLDER=$COLCON_WORKSPACE_FOLDER \
  CONTAINER_USER=$CONTAINER_USER \
  HOME_VOLUME_FOLDER=$HOME_VOLUME_FOLDER \
  SSH_AUTH_SOCK_HOST_PATH="$SSH_AUTH_SOCK" \
  SSH_AUTH_SOCK_CONTAINER_PATH="/home/$CONTAINER_USER/.ssh-agent/ssh-agent.sock" \
  USER_UID="$USER_UID" \
  USER_GID="$USER_GID" \
  docker-compose \
  -p "$PROJECT_NAME" \
  -f docker-compose.yml \
  ${COMPOSE_ADD_ONS_OPT[@]} \
  --env-file .env \
  up ${COMPOSE_OPT_ARGS[@]} -d devel

# Check if the service is running
if docker-compose -p "$PROJECT_NAME" ps --services --filter status=stopped | grep -x -q devel; then
  echo "Failed to run devel service. Try running run-devel.sh with -b option."
  exit 1
fi

# shellcheck disable=SC2086
docker-compose -p "$PROJECT_NAME" exec --user "$CONTAINER_USER" -w "/home/$CONTAINER_USER" devel $EXEC_COMMAND

CONTAINER_ID=$(docker-compose -p "$PROJECT_NAME" ps -q devel)
if [ -z "$(docker inspect "$CONTAINER_ID" --format='{{join .ExecIDs ""}}')" ]; then
  docker-compose -p "$PROJECT_NAME" stop devel
fi
