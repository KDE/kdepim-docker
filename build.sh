#!/bin/bash

if [ $(id -u) -eq 0 ]; then
    echo "Don't run this script as root!"
    exit 1
fi

docker_exe="docker"

usage() {
    echo "Usage: $0 [-n]"
    echo "-n    Use nvidia-docker instead of docker executable (see README for details)"
    exit 1
}

while getopts ":n" o; do
    case "${o}" in
        n)
           docker_exe="nvidia-docker"
           ;;
        *)
           usage
           ;;
    esac
done
shift $((OPTIND-1))

container_name="kdepim:dev"
num=$(${docker_exe} ps -f name=${container_name} | wc -l)
if [ ${num} -gt 1 ]; then
    read -p "Do you want to destroy and recreate the existing ${container_name} container? [y/n] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        ${docker_exe} stop ${container_name}
        ${docker_exe} rm ${container_name}
    fi
fi

${docker_exe} build --no-cache --tag ${container_name} .

