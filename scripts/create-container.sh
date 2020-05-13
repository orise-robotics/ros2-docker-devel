#!/bin/bash

function usage() {
    printf "Usage: $0 image container\n\n"
    printf "Options:\n"
    printf "  -h\t\t\t Shows this help message\n"
    exit 0
}

while getopts "h" OPT; do
    case "${OPT}" in
    "h") usage ;;
    "?") exit 1 ;;
    esac
done

DOCKER_IMAGE=${1}
CONTAINER_NAME=${2}

echo ${DOCKER_IMAGE}
echo ${CONTAINER_NAME}

echo !"$(docker image ls -aq --filter reference=${DOCKER_IMAGE})"

if [ !"$(docker image ls -aq --filter reference=${DOCKER_IMAGE})" ]; then
    echo "ENTERED"
    docker create -it \
        --net host \
        --volume="$HOME/docker_ws/volumes/${CONTAINER_NAME}:/home/${USER}:rw" \
        --volume="/etc/localtime:/etc/localtime:ro" \
        --env="TERM" \
        --workdir="/home/${USER}" \
        --name ${CONTAINER_NAME} \
        --privileged \
        "${DOCKER_IMAGE}"
fi
