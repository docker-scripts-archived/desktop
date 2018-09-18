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

    ds inject setup-services.sh
    ds inject apache2-proxy.sh
    #ds inject nginx-proxy.sh

    # copy accounts.txt
    [[ -f accounts.txt ]] || cp $APP_DIR/accounts.txt .

    ds inject create-accounts.sh
}
