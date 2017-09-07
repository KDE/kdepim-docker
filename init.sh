#!/bin/sh

dbus-daemon --system --fork

# Start bash
su -c "dbus-launch /bin/bash" -l neon


# Clean up, stop the daemon
kill -TERM `cat /var/run/dbus/pid`
rm /var/run/dbus/pid
