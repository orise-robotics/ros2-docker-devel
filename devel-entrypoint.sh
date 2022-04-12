#!/usr/bin/env bash

set -e

if [ ! "$(getent passwd "$USER")" ]; then
    useradd -s /bin/bash -u "${USER_UID}" -G sudo -m "${USER}"
    groupmod -g "${USER_GID}" "${USER}"
    echo "${USER} ALL=(ALL) NOPASSWD:ALL" >>/etc/sudoers.d/"${USER}"
    chmod 0440 /etc/sudoers.d/"${USER}"
elif [[ ! "$(id -u "$USER")" == "${USER_UID}" || ! "$(id -g "$USER")" == "${USER_GID}" ]]; then
    exit 1
fi

[ ! -f "/home/$USER/.basrhc" ] && gosu "$USER" cp /etc/skel/.bashrc "/home/$USER"

exec gosu "$USER" "$@"
