FROM kdeneon/plasma:unstable
MAINTAINER Daniel Vrátil <dvratil@kde.org>

USER root

RUN apt-get update && apt-get dist-upgrade -y

# Setup environment for NVIDIA
LABEL com.nvidia.volumes.needed="nvidia_driver"
RUN echo "/usr/local/nvidia/lib" >> /etc/ld.so.conf.d/nvidia.conf && \
    echo "/usr/local/nvidia/lib64" >> /etc/ld.so.conf.d/nvidia.conf
ENV PATH /usr/local/nvidia/bin:/usr/local/cuda/bin:${PATH}
ENV LD_LIBRARY_PATH /usr/local/nvidia/lib:/usr/local/nvidia/lib64:${LD_LIBRARY_PATH}

# uninstall the KDE PIM that ships in the base image
RUN apt-get remove -y \
  kdesdk-devenv-dependencies \
  && apt autoremove -y

# Minimal dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
  cmake extra-cmake-modules g++ gettext git libboost-all-dev \
  libfreetype6-dev make libyaml-perl libyaml-libyaml-perl

# requirements for clazy
#RUN apt-get update && apt-get install -y --no-install-recommends \
#  clang llvm-dev libclang-dev

# build and install clazy
#RUN git clone git://anongit.kde.org/clazy.git \
#    && cd clazy \
#    && cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release \
#    && make install
#RUN rm -rf clazy

# install KDE PIM dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
  qtbase5-private-dev qtwebengine5-dev libqt5x11extras5-dev qttools5-dev \
  libqt5svg5-dev  libqt5texttospeech5-dev libqt5sql5-mysql libqt5sql5-psql \
  libqca-qt5-2-dev libqt5networkauth5-dev qt5keychain-dev qtlocation5-dev \
  qtmultimedia5-dev qtquickcontrols2-5-dev qtdeclarative5-private-dev \
  \
  libassuan-dev bison libgrantlee5-dev libical3-dev libkolabxml-dev liblzma-dev \
  libxslt-dev libphonon4qt5-dev libsqlite3-dev libxapian-dev xsltproc \
  libgpgmepp-dev libgpgme-dev libsasl2-dev libldap2-dev libqrencode-dev libdmtx-dev \
  libkaccounts-dev \
  \
  libkf5archive-dev libkf5auth-dev libkf5bookmarks-dev libkf5calendarcore-dev libkf5codecs-dev \
  libkf5completion-dev libkf5config-dev libkf5configwidgets-dev libkf5contacts-dev \
  libkf5coreaddons-dev libkf5crash-dev libkf5dav-dev libkf5dbusaddons-dev libkf5declarative-dev \
  libkf5dnssd-dev libkf5doctools-dev libkf5emoticons-dev \
  libkf5globalaccel-dev libkf5guiaddons-dev libkf5holidays-dev libkf5i18n-dev libkf5iconthemes-dev \
  libkf5itemmodels-dev libkf5itemviews-dev libkf5jobwidgets-dev libkf5kcmutils-dev \
  libkf5kdelibs4support-dev libkf5kio-dev kross-dev libkf5newstuff-dev \
  libkf5notifications-dev libkf5notifyconfig-dev libkf5parts-dev libkf5prison-dev \
  libkf5qqc2desktopstyle-dev libkf5runner-dev \
  libkf5service-dev libkf5sonnet-dev libkf5syntaxhighlighting-dev libkf5syndication-dev \
  libkf5texteditor-dev libkf5textwidgets-dev libkf5wallet-dev libkf5widgetsaddons-dev \
  libkf5windowsystem-dev libkf5xmlgui-dev libkf5xmlrpcclient-dev libkf5networkmanagerqt-dev \
  libkf5purpose-dev \
  breeze-icon-theme flex gpgsm osmctools pinentry-qt xsdcxx

# runtime dependencies (MariaDB, postgresql)
RUN apt-get update && apt-get install -y --no-install-recommends \
  mariadb-server postgresql

# dependencies for development
RUN apt-get update && apt-get install -y --no-install-recommends \
  cmake-curses-gui ccache icecc\
  less vim strace qtcreator kdevelop valgrind gdb\
  qt5-doc qt*5-doc

# Make polkit-1 writable - kalarm installs its policy there because
# that's where kauth frameworks expects it. This is a development
# environment, so it's not a huge problem, but don't try this at
# home, kids.
RUN chmod a+w /usr/share/polkit-1/actions

# Configure pulseaudio to connect to host pulseaudio. Requires running
# container with -v=/var/run/${USER_UID}/pulse:/run/user/1000/pulse:rw,z
# Based on https://github.com/TheBiggerGuy/docker-pulseaudio-example
COPY pulse-client.conf /etc/pulse/client.conf

# Add neon to audio group
RUN usermod -a -G audio neon

# Make XDG_RUNTIME_DIR owned by the user
RUN mkdir -p /run/user/1000 && chown -R neon:neon /run/user/1000/ && chmod 7700 /run/user/1000/
RUN mkdir -p /var/run/dbus
# Make cache dire owned by the user (needed for kdevelop)
RUN mkdir -p /home/neon/.cache && chown -R neon: /home/neon/.cache


################# USER actions ####################
USER neon

# Clone & setup kdesrc-build

RUN git clone https://invent.kde.org/sdk/kdesrc-build.git
COPY kdesrc-buildrc .kdesrc-buildrc
COPY kde-env /home/neon/.kde-env
COPY kdepim-env /home/neon/.kdepim-env
COPY start-iceccd.sh /home/neon/.start-iceccd.sh
COPY setup-dbus.sh /home/neon/.setup-dbus.sh
RUN mkdir kdepim

# Enable the environment
RUN echo '\n\nsource /home/neon/.kde-env\n' >> ~/.bashrc
RUN echo 'source /home/neon/.kdepim-env\n' >> ~/.bashrc
RUN echo 'source /home/neon/.setup-dbus.sh\n' >> ~/.bashrc
RUN echo 'source /home/neon/.start-iceccd.sh\n' >> ~/.bashrc

# Make the ccache bigger (the default 5G is not enough for PIM)
RUN mkdir /home/neon/kdepim/.ccache \
    && echo 'max_size = 10.0G' > /home/neon/kdepim/.ccache/ccache.conf

# Copy init.sh and start it
COPY init.sh /usr/local/bin/init.sh
ENTRYPOINT [ "/bin/bash" ]
