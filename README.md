# KDE PIM Docker for developers

This repository contains Dockerfile to create a Docker image for developing
KDE PIM. The image is based on KDE Neon Developer edition and has all the
dependencies needed to compile KDE PIM from source code and run Akonadi and
Kontact inside the container.

You can find more details about this Docker image and how to use it on our
[Docker wiki page on community.kde.org](https://community.kde.org/KDE_PIM/Docker).

## Building Docker image

Please check our [wiki page](https://community.kde.org/KDE_PIM/Docker) first
regarding using different GPU drivers.

In order to build the Docker image, run the `build.sh` script. If you are
using proprietary NVIDIA drivers, run the script with `-n` switch.

The command will create kdepim:dev Docker image.

## Running Docker container

The first time you should create a directory on your host system where you
want to have the KDE PIM sources, build and runtime directories etc. stored.

To run the container, use the `run.sh` script:

`run.sh /path/to/the/directory`

If you are using proprietary NVIDIA drivers, run the script with `-n` switch:

`run.sh -n /path/to/the/directory`

The content of the directory will be available in the container in the
/home/neon/kdepim directory.

## Building and updating KDE PIM

Once inside the container, you can use the following command to compile the
entire KDE PIM:

`kdesrc-build kde-pim`

This will take a lot of time the first time, but all subsequent builds will be
faster thanks. You can also build use a specific repository name instead of the
`kde-pim` group.

Check the [kdesrc-build documentation](https://kdesrc-build.kde.org) for more
details about KDE PIM.

kdesrc-build will clone all the repositories into /home/neon/kdepim/src/kde/pim,
build directories (where you can run `make` manually are in /home/neon/kdepim/build/kde/pim.
The binaries are installed into /home/neon/kdepim/install (and the environment
of the container is adjusted to work with the custom installation prefix).


## Development tools

There's [KDevelop](https://www.kdevelop.org) and [QtCreator](https://www.qt.io/ide/)
preinstalled in the container and you can run them from there. You can also use
them from outside of the container, but code completion might not work perfectly.

You can also any other IDE of your choice either by installing it into the container
with apt-get, or use it from outside of the container.

## Contributing

Please upload patches to [phabriactor.kde.org](https://phabricator.kde.org) for
review.


## Contact

If you have any questions regarding contributing to KDE PIM or this Docker image,
feel free to contact us on the KDE PIM mailing list (kde-pim@kde.org) or on the
#kontact IRC channel on Freenode.
