#!/bin/bash
# Check if the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root. Please use sudo or switch to the root user."
    exit 1
fi
# Check if the script is run in a Docker container
if [ -f /.dockerenv ]; then
    echo "This script cannot be run inside a Docker container."
    exit 1
fi
whiUsermod=$(which usermod)
if [ -z "$whiUsermod" ]; then
    mkdir -p /root/backup/etc
    cp /etc/profile /root/backup/etc
    sed -i 's#PATH=".*"#PATH="/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games:/sbin:/usr/sbin:/usr/local/sbin"#g' /etc/profile
    source /etc/profile
fi
