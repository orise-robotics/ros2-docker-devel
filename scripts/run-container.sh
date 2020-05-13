#!/bin/bash

function usage() {
    printf "Usage: $0 container\n\n"
    printf "Options:\n"
    printf "  -h\t\t\t Shows this help message\n"
    exit 0
}


while getopts "ht:x" OPT; do
    case "${OPT}" in
        "h") usage;;
        "?") exit 1;;
    esac
done

CONTAINER_NAME=${1}

if [ ! "$(docker ps -q -f name=${CONTAINER_NAME})" ]; then
    docker start -ai ${CONTAINER_NAME}
else
    docker exec -ti ${CONTAINER_NAME} /bin/bash
fi

