#!/usr/bin/env bash

if ! id "$CONTAINER_USER"&>/dev/null; then
    useradd -ls /bin/bash -u "$USER_UID" -G sudo -m "$CONTAINER_USER"
    echo "$CONTAINER_USER ALL=(ALL) NOPASSWD:ALL" >> "/etc/sudoers.d/$CONTAINER_USER"
    chmod 0440 "/etc/sudoers.d/$CONTAINER_USER"
fi

usermod -u "${USER_UID}" "$CONTAINER_USER"
groupmod -g "$USER_GID" "$CONTAINER_USER"
chown -R "$USER_UID:$USER_GID" "/home/$CONTAINER_USER"

exec gosu "$CONTAINER_USER" "$@"
