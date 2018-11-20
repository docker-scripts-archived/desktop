cmd_config_help() {
    cat <<_EOF
    config
        Run configuration scripts inside the container.

_EOF
}

cmd_config() {
    ds inject ubuntu-fixes.sh
    ds inject set_prompt.sh
    ds inject ssmtp.sh

    [[ -n $GUAC_ADMIN ]] && ds inject guacamole.sh

    if [[ -n $ADMIN_USER ]]; then
	ds exec bash -c "echo $ADMIN_USER:'$ADMIN_PASS' | /app-scripts/users.sh create"
	ds inject make-admin.sh $ADMIN_USER
    fi

    ds inject config-accounts.sh
    [[ -f accounts.txt ]] || cp $APP_DIR/accounts.txt .
    ds inject users.sh create /host/accounts.txt
    ds inject login.sh

    # get a letsencrypt ssl certificate
    local email=$GMAIL_ADDRESS
    [[ -n $SMTP_DOMAIN ]] && email="admin@$SMTP_DOMAIN"
    ds @wsproxy get-ssl-cert $email $DOMAIN
}
