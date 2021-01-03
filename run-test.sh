#!/bin/env bash

function usage() {
    printf "Usage: %s [options] PACKAGE\n" "$0"
    printf "Run the tests of the provided PACKAGE (format: [meta-package/]package) in an orise containter defined by ROS_DISTRO\n"
    printf "The source is provided by a VCStool .repos file through the --source option or setting the SRC_REPOS varible in the .env file (default)\n\n"
    printf "Options:\n"
    printf "  -b|--build\t\t Force image build\n"
    printf "  -h|--help\t\t Shows this help message\n"
    printf "  -d|--distro ROS_DISTRO\t ROS distro [default: defined in .env file]. Creates/runs a container named 'orise-ROS_DISTRO-test'.\n"
    printf "  -s|--source SRC_REPOS_FILE\t VCStool .repos file [default: defined in .env file]\n"

    exit 0
}

# shellcheck source=/dev/null
source .env

while [ -n "$1" ]; do
    case $1 in
    -h | --help) usage ;;
    -b | --build)
        BUILD_IMAGE_OPT="--build"
        ;;
    -d | --distro)
        ROS_DISTRO=$2
        shift
        ;;
    -s | --source)
        SRC_REPOS=$2
        shift
        ;;
    -?*)
        echo "Unknown option '$1'" 1>&2
        exit 1
        ;;
    *)
        PACKAGE=$1
        break
        ;;
    esac
    shift
done

CONTAINER_NAME="orise-$ROS_DISTRO-test"
SRC_REPOS=$(realpath "$SRC_REPOS")

# TODO: setup apt-cache volume

ROS_DISTRO=$ROS_DISTRO \
  CONTAINER_NAME=$CONTAINER_NAME \
  SRC_REPOS=$SRC_REPOS \
  PACKAGE=$PACKAGE \
  docker-compose --env-file .env up $BUILD_IMAGE_OPT test

docker-compose stop test
