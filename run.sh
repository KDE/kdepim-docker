#!/bin/sh

if [ $(id -u) -eq 0 ]; then
    echo "Don't run this script as root"
    exit 1
fi

docker_exe="docker"

usage()
{
    echo "Usage: $0 [-n] container | directory"
    echo "  -n         Use nvidia-docker instead of docker executable (see README for details)"
    echo "  container  An existing development container name."
    echo "             See 'docker ps -a'."
    echo "  directory  Location to use for a new development container."
    echo "             Final path component will be the container name."
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

container_name=`basename $1`

# Is kdepim-dev already running?
num=$(${docker_exe} ps -f name=${container_name} | wc -l)
if [ ${num} -eq 2 ]; then
    if [ "${attach}" = true ]; then
        # Attach to it
        ${docker_exe} attach ${container_name}
    else
        ${docker_exe} exec -it -u neon ${container_name} bash
    fi
else
    # Just stopped?
    num=$(${docker_exe} ps -a -f name=${container_name} | wc -l)
    if [ ${num} -eq 2 ]; then
        # Start it and attach to it
        ${docker_exe} start -ai ${container_name}
    elif [ ! -d $1 -o ! -w $1 ]; then
        echo "$1 is not a container name or a writable directory"
        exit 1
    else
        # Create a new container from the kdepim:dev image
        # using directory $1 for repository check-outs.
        user=$(id -u)
        ${docker_exe} run \
            -ti \
            -e DISPLAY \
            -e ICECC_SERVER \
            -v=/tmp/.X11-unix:/tmp/.X11-unix:rw,z \
            -v=/run/user/${user}/pulse:/run/user/1000/pulse:rw,z \
            -v=$1:/home/neon/kdepim:rw,z \
            --privileged \
            --name ${container_name} \
            kdepim:dev
    fi
fi
