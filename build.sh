#!/bin/sh

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

${docker_exe} build --tag kdepim:dev .
