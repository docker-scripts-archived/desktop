include(bionic)

### Install the desktop and display manager
RUN DEBIAN_FRONTEND=noninteractive \
    apt install --yes xubuntu-core lightdm
RUN systemctl set-default graphical.target

### Install vnc server and noVNC
RUN apt install --yes \
    novnc websockify net-tools python-numpy \
    vnc4server

RUN apt install --yes apache2
#RUN apt install --yes nginx

### Install additional packages
sinclude(packages)
