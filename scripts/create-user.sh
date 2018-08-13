#!/bin/bash -x

user=${1:-user}
pass=${2:-pass}
home=/home/$user

### create account
useradd -d $home -m -s /bin/bash -U  $user
chmod o-r -R $home/

### set password
echo "$user:$pass" | chpasswd

exit 0

### enable color prompt
sed -i $home/.bashrc \
    -e '/^#force_color_prompt=/c force_color_prompt=yes'

### allow to use sudo without password
echo "$user ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/$user
chmod 0440 /etc/sudoers.d/$user
echo "alias sudo='sudo -h 127.0.0.1'" >> $home/.bash_aliases

echo 'source /novnc/generate_container_user' >> $home/.bashrc
