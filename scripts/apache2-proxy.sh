#!/bin/bash -x

source /host/settings.sh

### setup the configuration for desktop
cat <<EOF > /etc/apache2/sites-available/desktop.conf
<VirtualHost *:80>
    ServerName $DOMAIN
    ProxyPass / http://127.0.0.1:6901/
    ProxyPassReverse / http://127.0.0.1:6901/
    ProxyRequests off
</VirtualHost>
EOF
### we need to refer to this apache2 config by the name "$DOMAIN.conf" as well
ln /etc/apache2/sites-available/{desktop,$DOMAIN}.conf

### update config and restart apache2
a2enmod ssl proxy proxy_http rewrite
a2ensite desktop
a2dissite 000-default
service apache2 restart
