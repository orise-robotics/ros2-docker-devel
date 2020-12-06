ARG ROS_DISTRO

FROM ros:${ROS_DISTRO}-ros-base

ARG DOCKER_USER=orise

RUN useradd -s /bin/bash ${DOCKER_USER}

# install gosu
RUN set -eux; \
    apt-get update; \
    apt-get install -y gosu; \
    rm -rf /var/lib/apt/lists/*; \
    gosu nobody true

# install common dev tools
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

RUN mkdir -p /home/${DOCKER_USER}/devel_ws && chown ${DOCKER_USER}:${DOCKER_USER} /home/${DOCKER_USER}/devel_ws;

WORKDIR /home/${DOCKER_USER}/devel_ws

COPY docker-entrypoint.sh /usr/bin/docker-entrypoint.sh

ENTRYPOINT ["docker-entrypoint.sh"]

CMD ["bash"]
