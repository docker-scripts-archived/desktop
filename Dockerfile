include(bionic)

### uniminimize
RUN echo y | unminimize

### update and upgrade
RUN apt update &&\
    apt upgrade --yes

### add LinuxMint repository
RUN echo "deb http://packages.linuxmint.com tara main upstream import backport" \
    > /etc/apt/sources.list.d/linuxmint.list
RUN apt install --yes gnupg &&\
    apt-key adv --recv-key A6616109451BBBF2

### setup apt preferences
RUN echo "\
Package: *\n\
Pin: origin build.linuxmint.com\n\
Pin-Priority: 700\
" > /etc/apt/preferences.d/official-extra-repositories.pref

RUN echo "\
Package: *\n\
Pin: origin live.linuxmint.com\n\
Pin-Priority: 750\n\
\n\
Package: *\n\
Pin: release o=linuxmint,c=upstream\n\
Pin-Priority: 700\n\
\n\
Package: *\n\
Pin: release o=Ubuntu\n\
Pin-Priority: 500\n\
" > /etc/apt/preferences.d/official-package-repositories.pref

### update and upgrade
RUN apt update &&\
    apt upgrade --yes

### install the desktop and display manager
RUN DEBIAN_FRONTEND=noninteractive \
    apt install --yes \
        lightdm lightdm-settings slick-greeter \
        mint-meta-xfce mint-meta-mate
RUN systemctl set-default graphical.target

### install x2go server
RUN apt install --yes x2goserver

### install vnc server and noVNC
RUN apt install --yes \
    novnc websockify net-tools python-numpy \
    vnc4server

### install Guacamole dependences
RUN DEBIAN_FRONTEND=noninteractive \
    apt install --yes \
        build-essential libcairo2-dev libjpeg-turbo8-dev libpng-dev libossp-uuid-dev \
        libavcodec-dev libavutil-dev libswscale-dev \
        libfreerdp-dev libpango1.0-dev libssh2-1-dev libtelnet-dev \
        libvncserver-dev libpulse-dev libssl-dev libvorbis-dev libwebp-dev \
        mysql-server mysql-client mysql-common mysql-utilities libmysql-java \
        gcc-6 dpkg-dev tomcat8 vnc4server apache2 git \
        xrdp xorgxrdp xrdp-pulseaudio-installer pulseaudio

### install additional packages
sinclude(packages)
