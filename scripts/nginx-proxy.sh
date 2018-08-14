#!/bin/bash -x

source /host/settings.sh

### setup the configuration for desktop
### see: https://github.com/novnc/noVNC/wiki/Proxying-with-nginx
cat <<EOF > /etc/nginx/sites-available/desktop
server {
        #listen 443 ssl;
        listen 80;
        #server_name $DOMAIN;

        #ssl_certificate       /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
        #ssl_certificate_key   /etc/letsencrypt/live/$DOMAIN/privkey.pem;

        location /websockify {
                proxy_http_version 1.1;
                proxy_pass http://127.0.0.1:6901/;
                proxy_set_header Upgrade \$http_upgrade;
                proxy_set_header Connection "upgrade";

                # VNC connection timeout
                proxy_read_timeout 61s;

                # Disable cache
                proxy_buffering off;
        }

        location / {
                index vnc.html;
                alias /usr/share/novnc/;
                try_files \$uri \$uri/ /vnc.html;
        }
}
EOF

### update config and restart nginx
cd /etc/nginx/sites-enabled/
rm default
ln -s /etc/nginx/sites-available/desktop .
service nginx restart
