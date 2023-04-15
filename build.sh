#!/bin/bash

if [ $(id -u) -eq 0 ]; then
    echo "Don't run this script as root!"
    exit 1
fi

docker_exe="docker"
qt_version=5
build_args="--no-cache" # default docker build args

usage() {
    echo "Usage: $0 [-n] [-q VERSION]"
    echo "-n    Use nvidia-docker instead of docker executable (see README for details)"
    echo "-q    set the QT version that should be supported in image (default 5)"
    exit 1
}

while getopts ":nq:" o; do
    case "${o}" in
        n)
           docker_exe="nvidia-docker"
           ;;
        q)
           qt_version="$OPTARG"
           ;;
        *)
           usage
           ;;
    esac
done
shift $((OPTIND-1))

if [ "$qt_version" = "6" ]; then
    container_name="kdepim:qt6-dev"
else
    container_name="kdepim:dev"
fi

num=$(${docker_exe} images -f reference=${container_name} | wc -l)
if [ ${num} -gt 1 ]; then
    read -p "Do you want to destroy and recreate the existing ${container_name} container? [y/n] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        ${docker_exe} stop ${container_name}
        ${docker_exe} rm ${container_name}
    fi
fi

${docker_exe} build \
    ${build_args} \
    --tag ${container_name} \
    --build-arg QTVERSION=${qt_version} \
    .
