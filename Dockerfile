ARG ROS_DISTRO

FROM ros:${ROS_DISTRO}-ros-base

ARG DEBIAN_FRONTEND=noninteractive

# make security updates
RUN apt-get update && \
    apt-get install -y --no-install-recommends unattended-upgrades && unattended-upgrade && \
    rm -rf /var/lib/apt/lists/*

# install common dev tools
RUN export DEBIAN_FRONTEND=noninteractive; \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    bash-completion \
    pkg-config \
    git \
    python3-pip \
    ssh \
    vim \
    && rm -rf /var/lib/apt/lists/*

# install ament_flake8 non-declared pip deps
RUN pip3 install --no-cache-dir \
    flake8-blind-except \
    flake8-builtins \
    flake8-class-newline \
    flake8-comprehensions \
    flake8-deprecated \
    flake8-docstrings \
    flake8-import-order \
    flake8-quotes

# install ros tools
RUN apt-get update && \
    apt-get install --no-install-recommends -y \
    python3-colcon-mixin \
    python3-vcstool \
    python3-colcon-common-extensions \
    && rm -rf /var/lib/apt/lists/*

RUN echo "source /opt/ros/$ROS_DISTRO/setup.bash" >> /etc/bash.bashrc
RUN echo "PS1='\[\033[01;35m\]ros-$ROS_DISTRO@devel\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '" >> /etc/skel/.bashrc

ENV GPG_TTY=$(tty)

COPY docker-entrypoint.sh /usr/bin/docker-entrypoint.sh

ARG CONTAINER_USER=orise
RUN useradd -s /bin/bash ${CONTAINER_USER} && \
    echo "${CONTAINER_USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/${CONTAINER_USER} && \
    chmod 0440 /etc/sudoers.d/${CONTAINER_USER}

USER ${CONTAINER_USER}
WORKDIR /home/${CONTAINER_USER}/

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["bash"]
