#!/bin/bash -x

# don't show a list of users on login
cat <<EOF > /etc/lightdm/lightdm.conf.d/71-hide-users.conf
[SeatDefaults]
greeter-hide-users=true
EOF
systemctl restart lightdm
