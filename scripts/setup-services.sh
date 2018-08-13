#!/bin/bash -x

source /host/settings.sh

### set vnc password
if [[ -z $VNC_PW ]]; then
    vnc_command='Xvnc -SecurityTypes None'
else
    echo "$VNC_PW" | vncpasswd -f >> /etc/vncpasswd
    chmod 600 /etc/vncpasswd
    vnc_command='Xvnc -SecurityTypes VncAuth -PasswordFile /etc/vncpasswd'
fi

### enable remote display and VNC server
cat <<EOF > /etc/lightdm/lightdm.conf
[XDMCPServer]
enabled=true

[VNCServer]
enabled=true
command=$vnc_command
port=5900
width=${VNC_WIDTH:-1024}
height=${VNC_HEIGHT:-768}
depth=${VNC_DEPTH:-24}
EOF
systemctl restart lightdm.service

### start noVNC service
cat <<EOF > /etc/systemd/system/websockify.service
[Unit]
Description = start noVNC service
After = syslog.target network.target

[Service]
ExecStart = /usr/bin/websockify --web=/usr/share/novnc/ 6901 localhost:5900

[Install]
WantedBy = graphical.target
EOF
systemctl enable websockify.service
systemctl start websockify.service
