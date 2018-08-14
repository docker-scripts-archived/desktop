#!/bin/bash -x
### Create accounts for all the students.
### The file accounts.txt contains a list of usernames and passwords
### separated by column (:).

addgroup student
while IFS=: read user pass
do
    echo $user:$pass
    useradd -d /home/$user -m -s /bin/bash -U  $user
    adduser $user student
    echo "$user:$pass" | chpasswd
    chmod o-r -R /home/$user/
    sed -i /home/$user/.bashrc \
        -e '/^#force_color_prompt=/c force_color_prompt=yes'
done < /host/accounts.txt

### place some resource limits
sed -i /etc/security/limits.conf -e '/^### custom/,$ d'
cat <<EOF >> /etc/security/limits.conf
### custom
@student        hard    nproc           1000
*               hard    core            0
@noroot         hard    date            102400
@student        hard    cpu             2
@student        hard    maxlogins       3
EOF
