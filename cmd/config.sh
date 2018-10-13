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

    ds inject guacamole.sh

    # copy accounts.txt
    [[ -f accounts.txt ]] || cp $APP_DIR/accounts.txt .

    ds inject config-accounts.sh
    ds inject users.sh create /host/accounts.txt
}
