# ros2-docker-devel

![dockerhub-deploy](https://github.com/orise-robotics/ros2-docker-devel/workflows/dockerhub-deploy/badge.svg?branch=master)
![container-scan](https://github.com/orise-robotics/ros2-docker-devel/workflows/container-scan/badge.svg?branch=master)
![super-lint](https://github.com/orise-robotics/ros2-docker-devel/workflows/super-lint/badge.svg?branch=master)

Helper tool to develop ROS2 packages using Docker.

## Setup

The scripts provided were tested in Debian-based distributions (especially Ubuntu), but it is supposed to work on any Linux distribution.

Required Dependencies:

* [Docker 20.10+](https://docs.docker.com/engine/install/)
* [Docker Compose 1.29+](https://docs.docker.com/compose/install/)

### Nvidia GPU

To access Nvidia GPU resources in the container, install [`nvidia-container-runtime`](https://nvidia.github.io/nvidia-container-runtime/). For Debian-based distros:

```
curl -s -L https://nvidia.github.io/nvidia-container-runtime/gpgkey | \
  sudo apt-key add -
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-container-runtime/$distribution/nvidia-container-runtime.list | \
  sudo tee /etc/apt/sources.list.d/nvidia-container-runtime.list
sudo apt-get update
sudo apt-get install nvidia-container-runtime
```

### SSH Forwarding

To be able to pull/push private repositories with SSH keys available in the host environment, the user needs to add a private key to `ssh-agent` ([Tutorial on Generating a new SSH key and adding it to the ssh-agent](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent)

## `ros2-devel.sh`

This script manages creation and execution of development containers. Once it is configured (through the `.env` file and command-line arguments), the developer just need to run `./ros2-devel.sh` to:

 - Build the image (or create the container) at the very first time you run it, or when you whish to create a fresh environment
 - Start the container (when it is not running), or attach the running container (create a new bash session)

The containers are identified by the PROJECT_PREFIX and ROS_DISTRO arguments, allowing the user to create multiple environments by varying ROS distributions and projects. For example, the user can create isolated environments to develop different projects under different distros by calling:

```bash
./ros2-devel.sh -d DISTRO -p PROJECT
```

For example, each of the following commands create a :
```bash
./ros2-devel.sh -p moveit2 -d foxy   # creates or attach to container 'moveit2_foxy'
./ros2-devel.sh -p moveit2 -d galactic  # creates or attach to container 'moveit2_galactic'
./ros2-devel.sh -p navigation2 -d foxy  # creates or attach to container 'navigation2_foxy'
```

Default arguments are defined in the `.env` file. Run `ros2-devel.sh -h` for more information.

## Using VSCode

We recommend you to try [vscode_ros2_ws](https://github.com/orise-robotics/vscode_ros2_ws), a vscode workspace with all the tools needed to develop ROS2 packages in development containers with ease.
