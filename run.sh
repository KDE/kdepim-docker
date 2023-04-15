#!/bin/sh

if [ $(id -u) -eq 0 ]; then
    echo "Don't run this script as root"
    exit 1
fi

docker_exe="docker"
qt_version=5

usage()
{
    echo "Usage: $0 [-n] [-q VERSION ] container | directory"
    echo "  -n         Use nvidia-docker instead of docker executable (see README for details)"
    echo "  -q         Set the QT version that should be supported in image (default 5)"
    echo "  container  An existing development container name."
    echo "             See 'docker ps -a'."
    echo "  directory  Location to use for a new development container."
    echo "             Final path component will be the container name."
    exit 1
}

while getopts "naq:" o; do
    case "${o}" in
        n)
            docker_exe="nvidia-docker"
            ;;
        q)
           qt_version="$OPTARG"
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

if [ "$qt_version" = "6" ]; then
    base_image="kdepim:qt6-dev"
else
    base_image="kdepim:dev"
fi

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
        args="-e DISPLAY \
            -e ICECC_SERVER \
            -e WAYLAND_DISPLAY \
            -e XDG_SESSION_TYPE \
            -v /tmp/.X11-unix:/tmp/.X11-unix:rw,z \
            -v $XDG_RUNTIME_DIR/pulse:$XDG_RUNTIME_DIR/pulse:rw,z \
            -v $1:/home/neon/kdepim:rw,z"

        if [ ! -z "$WAYLAND_DISPLAY" ] && [ -e $XDG_RUNTIME_DIR/$WAYLAND_DISPLAY ]; then
                args="${args} \
                    -v $XDG_RUNTIME_DIR/$WAYLAND_DISPLAY:$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY"
       fi
       ${docker_exe} run \
            -ti \
            ${args} \
            --user=$(id -u):$(id -g) \
            --privileged \
            --name ${container_name} \
            ${base_image}
    fi
fi
