ARG ROS_DISTRO

FROM ros:${ROS_DISTRO}-ros-base

RUN export DEBIAN_FRONTEND=noninteractive; \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    bash-completion \
    pkg-config \
    git \
    vim \
    && rm -rf /var/lib/apt/lists/*

# install ros tools
RUN apt-get update && \
    apt-get install --no-install-recommends -y \
    python3-colcon-mixin \
    python3-vcstool \
    python3-colcon-common-extensions \
    && rm -rf /var/lib/apt/lists/*

COPY devel_entrypoint.sh /usr/bin/devel_entrypoint.sh

ENTRYPOINT ["devel_entrypoint.sh"]

CMD ["bash"]
