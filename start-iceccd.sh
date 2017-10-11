function setup_icecc {
    echo "setup icecc"
    /usr/sbin/iceccd --no-remote -d -l /home/developer/iceccd.log -s ${ICECC_SERVER} -N docker
    export PATH=/usr/lib/ccache:$PATH
    export CCACHE_PREFIX=icecc
}

if [[ $ICECC_SERVER ]]; then
    if ! pidof iceccd > /dev/null; then
        setup_icecc
    fi
fi
