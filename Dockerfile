include(bionic)

### Install the desktop and display manager
RUN DEBIAN_FRONTEND=noninteractive \
    apt install --yes xubuntu-core lightdm
RUN systemctl set-default graphical.target

### Install vnc server and noVNC
RUN apt install --yes \
    novnc websockify net-tools python-numpy \
    vnc4server

### Install firefox and chrome browser
#RUN apt install --yes --install-recommends \
#    firefox chromium-browser chromium-browser-l10n chromium-codecs-ffmpeg
