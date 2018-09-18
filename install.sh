#!/bin/bash -x

export DEBIAN_FRONTEND=noninteractive
apt update
apt upgrade --yes
apt install --yes \
    novnc websockify net-tools python-numpy \
    vnc4server apache2

if [[ -d /vagrant ]]; then
    ln -sf /vagrant /host
else
    cd $(dirname $0)
    ln -sf $(pwd) /host
fi

/host/scripts/setup-services.sh
/host/scripts/apache2-proxy.sh
/host/scripts/create-accounts.sh

rm -f /host
