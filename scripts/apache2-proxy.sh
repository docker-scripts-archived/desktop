#!/bin/bash -x

source /host/settings.sh

### setup the configuration for desktop
cat <<EOF > /etc/apache2/sites-available/desktop.conf
<VirtualHost *:80>
    ServerName $DOMAIN

    ProxyPass / http://127.0.0.1:6901/
    ProxyPassReverse / http://127.0.0.1:6901/

    ProxyPass /websockify ws://127.0.0.1:6901/websockify retry=3
    ProxyPassReverse /websockify ws://127.0.0.1:6901/websockify retry=3

    ProxyRequests off
</VirtualHost>

# <VirtualHost _default_:443>
#         ServerName $DOMAIN
# 
#     	ProxyPass / http://127.0.0.1:6901/
#     	ProxyPassReverse / http://127.0.0.1:6901/
# 
#     	ProxyPass /websockify ws://127.0.0.1:6901/websockify retry=3
#     	ProxyPassReverse /websockify ws://127.0.0.1:6901/websockify retry=3
# 
#         ProxyRequests off
# 
#         SSLEngine on
#         SSLCertificateFile      /etc/letsencrypt/live/$DOMAIN/fullchain.pem
#         SSLCertificateKeyFile   /etc/letsencrypt/live/$DOMAIN/privkey.pem
#         #SSLCertificateChainFile /etc/letsencrypt/live/$DOMAIN/chain.pem
# 
#         SSLProxyEngine on
#         SSLProxyVerify none
#         SSLProxyCheckPeerCN off
#         SSLProxyCheckPeerName off
#         SSLProxyCheckPeerExpire off
# </VirtualHost>
EOF
### we need to refer to this apache2 config by the name "$DOMAIN.conf" as well
ln /etc/apache2/sites-available/{desktop,$DOMAIN}.conf

### update config and restart apache2
a2enmod ssl proxy proxy_http proxy_wstunnel rewrite
a2ensite desktop
a2dissite 000-default
service apache2 restart
