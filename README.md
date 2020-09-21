# My ROS Workspace

This repository provides simple tools to develop and test ROS and ROS2 packages using Docker.

## Build Images

Dockerfile defines multi-stage build with the targets:
1. `test-build`: the minimum needed to download and build a ROS package
2. `devel-build`: `test-build` + `ros-$ROS_DISTRO-ros-base` packages

The script `build-images.sh` automates the creation of the images given the target ROS distro name. For example:
```console
./build-images.sh dashing
```
Creates two images called `ros-dashing:test` and `ros-dashing:devel`.


## Test

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

## Develop

The script `run_devel.sh` creates a devel container (or start/attach to an existing one) given the target ROS distro. For example, the command:
```console
./run-devel.sh -d melodic
```
will attach to the container `ros-melodic-devel`.
