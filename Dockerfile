ARG ROS_DISTRO

FROM ros:${ROS_DISTRO}-ros-core

RUN export DEBIAN_FRONTEND=noninteractive; \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    bash-completion \
    curl \
    build-essential \
    pkg-config \
    sudo \
    git \
    locales \
    tzdata \
    vim \
    && rm -rf /var/lib/apt/lists/*

ARG PYTHON_VERSION

# install ros tools
RUN apt-get update && \
    apt-get install --no-install-recommends -y \
    python3-colcon-mixin \
    python${PYTHON_VERSION}-rosdep \
    python3-vcstool \
    python3-colcon-common-extensions \
    && rm -rf /var/lib/apt/lists/*

COPY devel_entrypoint.sh /usr/bin/devel_entrypoint.sh

ENTRYPOINT ["devel_entrypoint.sh"]

CMD ["bash"]
