#!/bin/bash -x

user=${1:-admin}

### allow to use sudo without password
echo "$user ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/$user
chmod 0440 /etc/sudoers.d/$user
echo "alias sudo='sudo -h 127.0.0.1'" >> /home/$user/.bash_aliases
