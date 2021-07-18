# ORise's ROS Workspace

![docker-deploy-foxy](https://github.com/open-br/ros_ws/workflows/docker-deploy-foxy/badge.svg?branch=master)
![docker-deploy-dashing](https://github.com/open-br/ros_ws/workflows/docker-deploy-dashing/badge.svg?branch=master)
![docker-build](https://github.com/open-br/ros_ws/workflows/docker-build/badge.svg?branch=master)

This repository provides simple tools to develop and test ROS and ROS2 packages using Docker.

## Dependencies

* [Docker 19.03+](https://docs.docker.com/engine/install/)
* [Docker Compose 1.28+](https://docs.docker.com/compose/install/)

## Develop within a Container

The script `run_devel.sh` creates a devel container (or start/attach to an existing one) given the target ROS distro. For example, the command:
```console
./run-devel.sh -d melodic
```
will attach to the container `ros-melodic-devel`.

We recommend you to try [vscode_ros2_ws](https://github.com/orise-robotics/vscode_ros2_ws), a vscode workspace with all the tools needed to develop ROS2 packages in ORise's development containers with ease.

To be able to pull/push private repositories with SSH keys available in the host environment, the user needs to add the private key to ssh-agent by running `ssh-add PRIVATE_KEY_PATH`.

## Test in a Container

The script `run_test.sh` starts a test container given the target ROS distro, then test the target package selected from the provided source list ([vcstools](https://github.com/dirk-thomas/vcstool) format). For example:

Given there is an already built test image for `noetic` and a file `my_srcs.repo` containing:
```yaml
repositories:
  navigation:
    type: git
    url: https://github.com/ros-planning/navigation
    version: noetic-devel
```
The command:
```console
./run-tests.sh -d noetic -s my_srcs.repos navigation/move_base
```
will get package source code, download the dependencies, build, install and test only the target library (it would run all the packages of the metapackage if only `navigation` is provided). This isolated build and test is particularly powerful to catch problems of missing dependencies and wrong installation.

## ORise Docker Images

We provide some ready-to-use development images in the [DockerHub](https://hub.docker.com/u/oriserobotics). However, you can also build the images yourself.

This repository provides two Dockerfiles:
1. `Dockerfile:` image for development purpose. It is based on `ros-$ROS_DISTRO-ros-base` image + basic development setup
2. `Dockerfile.test:` image for test purpose. It has the minimum set of tools to download and build a ROS package. It is based on the `ros:${ROS_DISTRO}-ros-core` image

The script `build-images.sh` automates the creation of the images given the target ROS distro name. For example:
```console
./build-images.sh -d foxy
```
Creates the development image `orise-foxy-devel`.

If you want the test image `orise-foxy-test` instead, you may pass the `--test` argument:
```console
./build-images.sh --test -d foxy
```

Run `./build-images.sh --help` for more information.
