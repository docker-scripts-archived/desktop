#!/bin/bash
### This script manage users accounts in bulk.
### It can be used to create, export, import, backup and restore.

usage() {
    cat <<EOF
Usage: $0 [<command>] [<filename>]

Commands:

    create [<user-file.txt>]
        Create new user accounts. Each line of the input contains
        a username, unencrypted password, and details, separated by ':'.
        If no file is given than read from stdin.

    export
        Export to stdout username, encrypted password and details
        for all the users.

    import [<user-file.passwd>]
        Import usernames, encrypted passwords and details from the export file.
        If no file is given than read from stdin.

    backup
        Backup home directories and users (username:password:details).
        The backup archive is stored on the directory 'backup/'.

    restore <backup-file.tgz>
        Restore home directories and user accounts from the given backup file.

EOF
}

create_user_accounts() {
    echo '--> Creating user accounts:'
    while IFS=: read username encrypted_password details; do
        echo "--> $username:$encrypted_password:$details"
        delgroup $username 2>/dev/null
        adduser $username "$@" \
                --gecos '' \
                --disabled-password
        usermod $username \
                --password "$encrypted_password" \
                --comment "$details"
        chown $username: -R /home/$username
    done
}

cmd_create() {
    local userfile=$1
    local username password encrypted_password details
    cat $userfile | while IFS=: read username password details; do
        encrypted_password="$(openssl passwd -stdin <<< $password)"
        echo "$username:$encrypted_password:$details"
    done | create_user_accounts
}

cmd_export() {
    local tmp1=$(mktemp /tmp/cmd_export.XXXXXX)
    local tmp2=$(mktemp /tmp/cmd_export.XXXXXX)
    grep /etc/shadow -E -v \
         -e ':\*:|:!:|^vagrant:' \
        | cut -d: -f1,2 | sort -t: > $tmp1
    grep /etc/passwd -E -v \
         -e '^vagrant:|/usr/sbin/nologin|/bin/false' \
        | cut -d: -f1,5 | sort -t: > $tmp2
    join -t: $tmp1 $tmp2
    rm $tmp1 $tmp2
}

cmd_import() {
    local userfile=$1
    cat $userfile | create_user_accounts
}

cmd_backup() {
    mkdir -p /host/backup/
    local backup_file="/host/backup/users-$(date +%Y%m%d).tgz"
    cmd_export > /home/user.pass
    tar -C /home --create --gzip \
        --exclude='vagrant' \
        --file=$backup_file .
    rm -f /home/user.pass
    echo $backup_file
}

cmd_restore() {
    local backup_file=$1
    [[ -z $backup_file ]] && usage
    [[ ! -f $backup_file ]] \
        && echo "Error: Cannot find file '$backup_file'." >&2 \
        && exit 1

    tar -C /home . --file=$backup_file --gunzip --extract
    cat /home/user.pass | create_user_accounts --no-create-home
    rm -f /home/user.pass
}

main() {
    local cmd=$1; shift
    case $cmd in
        create|export|import|backup|restore)
            cmd_$cmd "$@"
            ;;
        *) usage ;;
    esac
}

# make sure that the script is called as root
if [[ "$UID" != 0 ]]; then
    echo "Error: Use sudo or run script as root user." >&2
    exit 1
fi

# start the script
main "$@"
