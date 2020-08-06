####### TEST BUILD #######
ARG UBUNTU_DISTRO

FROM ubuntu:$UBUNTU_DISTRO as test-build

ARG UBUNTU_DISTRO

# setup timezone
RUN echo 'Etc/UTC' > /etc/timezone && \
    ln -s /usr/share/zoneinfo/Etc/UTC /etc/localtime && \
    apt-get update && \
    apt-get install -q -y --no-install-recommends tzdata && \
    rm -rf /var/lib/apt/lists/*

# install packages
RUN apt-get update && apt-get install -q -y --no-install-recommends \
    dirmngr \
    gnupg2 \
    && rm -rf /var/lib/apt/lists/*

# setup keys
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654

# setup sources.list
RUN echo "deb http://packages.ros.org/ros/ubuntu $UBUNTU_DISTRO main" > /etc/apt/sources.list.d/ros1-latest.list

# setup environment
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8

# install bootstrap tools
RUN apt-get update && apt-get install --no-install-recommends -y \
    build-essential \
    git \
    python3-rosdep \
    python3-vcstool \
    python3-colcon-common-extensions \
    && rm -rf /var/lib/apt/lists/*


WORKDIR /root
COPY test_entrypoint.sh /usr/bin/

CMD ["bash"]

####### DEVEL BUILD #######
FROM test-build as devel-build

ARG ROS_DISTRO

RUN apt-get update && apt-get install --no-install-recommends -y \
    ros-$ROS_DISTRO-ros-core \
    && rm -rf /var/lib/apt/lists/*
