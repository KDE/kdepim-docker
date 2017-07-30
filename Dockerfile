FROM kdeneon/plasma:dev-stable

USER root

RUN apt-get update && apt-get dist-upgrade -y

# Minimal dependencies
RUN apt-get install -y --no-install-recommends \
  cmake extra-cmake-modules g++ gettext git libboost-all-dev \
  libfreetype6-dev make

# requirements for clazy
RUN apt-get install -y --no-install-recommends \
  clang llvm-dev libclang-3.8-dev

# build and install clazy
RUN git clone git://anongit.kde.org/clazy.git \
    && cd clazy \
    && cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release \
    && make install
RUN rm -rf clazy

# install KDE PIM dependencies
RUN apt-get install -y --no-install-recommends \
  qtbase5-private-dev qtwebengine5-dev libqt5x11extras5-dev qttools5-dev \
  libqt5svg5-dev \
  \
  libassuan-dev bison libgrantlee5-dev libical-dev libkolabxml-dev libkolab-dev \
  libxslt-dev libphonon4qt5-dev libsqlite3-dev libxapian-dev xsltproc \
  libqgpgme7-dev libsasl2-dev libldap2-dev libqrencode-dev libdmtx-dev \
  \
  libkf5archive-dev libkf5auth-dev libkf5bookmarks-dev libkf5codecs-dev \
  libkf5completion-dev libkf5config-dev libkf5configwidgets-dev \
  libkf5coreaddons-dev libkf5crash-dev libkf5dbusaddons-dev libkf5declarative-dev \
  libkf5dnssd-dev libkf5doctools-dev libkf5emoticons-dev \
  libkf5globalaccel-dev libkf5guiaddons-dev libkf5i18n-dev libkf5iconthemes-dev \
  libkf5itemmodels-dev libkf5itemviews-dev libkf5jobwidgets-dev libkf5kcmutils-dev \
  libkf5kdelibs4support-dev libkf5kio-dev kross-dev libkf5newstuff-dev \
  libkf5notifications-dev libkf5notifyconfig-dev libkf5parts-dev libkf5runner-dev \
  libkf5service-dev libkf5sonnet-dev libkf5syntaxhighlighting-dev libkf5texteditor-dev \
  libkf5textwidgets-dev libkf5wallet-dev libkf5widgetsaddons-dev libkf5windowsystem-dev \
  libkf5xmlgui-dev libkf5xmlrpcclient-dev libkf5kdgantt2-dev

# dependencies for development
RUN apt-get install -y --no-install-recommends \
  cmake-curses-gui ccache \
  less vim strace qtcreator kdevelop valgrind gdb

# Make polkit-1 writable - kalarm installs its policy there because
# that's where kauth frameworks expects it. This is a development
# environment, so it's not a huge problem, but don't try this at
# home, kids.
RUN chmod a+w /usr/share/polkit-1/actions


################# USER actions ####################
USER neon

# Clone & setup kdesrc-build
RUN git clone git://anongit.kde.org/kdesrc-build
COPY kdesrc-buildrc kdesrc-build/kdesrc-buildrc
COPY setupenv /home/neon/.setupenv
RUN mkdir kdepim

# Setup the environment for building KDE PIM
RUN echo '___kdesrcbuild() { \n\
    pushd ~/kdesrc-build \n\ 
    ./kdesrc-build $@ \n\
    popd \n\
} \n\
alias kdesrc-build="___kdesrcbuild" \n\
\n\
export _PREFIX="/home/neon/kdepim/install" \n\
\n\
export PATH="${_PREFIX}/bin:${PATH:-/usr/local/bin:/usr/bin:/bin}" \n\
export LD_LIBRARY_PATH="${_PREFIX}/lib:${_PREFIX}/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH" \n\
export QT_PLUGIN_PATH="${_PREFIX}/lib/x86_64-linux-gnu/plugins:${QT_PLUGIN_PATH:-/usr/lib/x86_64-linux-gnu/qt5/plugins}" \n\
export QML2_IMPORT_PATH="${_PREFIX}/lib/x86_64-linux-gnu/qml:${QML2_IMPORT_PATH:-/usr/lib/x86_64-linux-gnu/qt5/qml}" \n\
export PKG_CONFIG_PATH="${_PREFIX}/lib/x86_64-linux-gnu/pkgconfig:${PKG_CONFIG_PATH:-/usr/lib/x86_64-linux-gnu/pkgconfig}" \n\
export XDG_DATA_DIRS="${_PREFIX}/share:${XDG_DATA_DIRS:-/usr/share}" \n\
export SASL_PATH="${_PREFIX}/lib/x86_64-linux-gnu/sasl2:${SASL_PATH:-/usr/lib/x86_64-linux-gnu/sasl2}" \n\
export XDG_CONFIG_DIRS="${_PREFIX}/etc/xdg:${XDG_CONFIG_DIRS:-/etc/xdg}" \n\
export PATH="/usr/lib/ccache:$PATH" \n\
export QT_SELECT=qt5 \n\
export CCACHE_DIR="/home/neon/kdepim/.ccache" \n\

' >> ~/.bashrc

# Make the ccache bigger (the default 5G is not enough for PIM)
RUN mkdir /home/neon/kdepim/.ccache \
    && echo 'max_size = 10.0G' > /home/neon/kdepim/.ccache/ccache.conf


CMD ["/home/neon/.setupenv" ]
