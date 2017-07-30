#!/bin/sh

if [ $(id -u) -eq 0 ]; then
    echo "Don't run this script as root"
    exit 1
fi

docker_exe="docker"

usage()
{
    echo "Usage: $0 [-n] homepath"
    echo "-n    Use nvidia-docker instead of docker executable (see README for details)"
    exit 1
}

while getopts "n" o; do
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

if [ -z $1 ]; then
    usage
fi

sudo ${docker_exe} run \
    -ti \
    -e=DISPLAY=$DISPLAY \
    -v=/tmp/.X11-unix:/tmp/.X11-unix:rw,z \
    -v=/run/user/$(id -u)/pulse:/run/user/1000/pulse:rw,z \
    -v=$1:/home/neon/kdepim:rw,z \
    --privileged \
    kdepim:dev
