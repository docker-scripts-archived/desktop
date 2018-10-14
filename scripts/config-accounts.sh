#!/bin/bash -x
### Setup configuration of the new accounts.

### create a group for student accounts
addgroup student --gid=999

### make new accounts belong to the student group
sed -i /etc/adduser.conf \
    -e '/^USERGROUPS=/ c USERGROUPS=no' \
    -e '/^USERS_GID=/ c USERS_GID=999' \
    -e '/^DIR_MODE=/ c DIR_MODE=0700'

### customize .bashrc of new accounts
cat <<'EOF' > /usr/local/sbin/adduser.local
#!/bin/bash
user_home=$4
sed -i $user_home/.bashrc -e '/^#force_color_prompt=/c force_color_prompt=yes'
EOF
chmod +x /usr/local/sbin/adduser.local

### place some resource limits
sed -i /etc/security/limits.conf -e '/^### custom/,$ d'
cat <<EOF >> /etc/security/limits.conf
### custom
@student        hard    nproc           10000
*               hard    core            0
@student        hard    cpu             2
@student        hard    maxlogins       3
EOF

