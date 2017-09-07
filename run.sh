#!/bin/sh

if [ $(id -u) -eq 0 ]; then
    echo "Don't run this script as root"
    exit 1
fi

docker_exe="docker"
container_name="kdepim-dev"

usage()
{
    echo "Usage: $0 [-n] homepath"
    echo "-n    Use nvidia-docker instead of docker executable (see README for details)"
    exit 1
}

while getopts "na" o; do
    case "${o}" in
        n)
            docker_exe="nvidia-docker"
            ;;
        a)
            attach=true
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

# Is kdepim-dev already running?
num=$(sudo ${docker_exe} ps -f name=${container_name} | wc -l)
if [ ${num} -eq 2 ]; then
    if [ "${attach}" = true ]; then
        # Attach to it
        sudo ${docker_exe} attach ${container_name}
    else
        sudo ${docker_exe} exec -it -u neon ${container_name} bash
    fi
else
    # Just stopped?
    num=$(sudo ${docker_exe} ps -a -f name=${container_name} | wc -l)
    if [ ${num} -eq 2 ]; then
        # Start it and attach to it
        sudo ${docker_exe} start -ai ${container_name}
    else
        # Create a new container from the kdepim:dev image
        sudo ${docker_exe} run \
            -ti \
            -e=DISPLAY=$DISPLAY \
            -v=/tmp/.X11-unix:/tmp/.X11-unix:rw,z \
            -v=/run/user/$(id -u)/pulse:/run/user/1000/pulse:rw,z \
            -v=$1:/home/neon/kdepim:rw,z \
            --privileged \
            --name ${container_name} \
            kdepim:dev
    fi
fi
