APP=desktop

### Docker settings.
IMAGE=desk.example.org
CONTAINER=desk.example.org
DOMAIN="desk.example.org"

WS_PORT=6901                         # websocket port for WebVNC
PORTS="$WS_PORT:$WS_PORT 2202:22 444:443"    # we need port 22 for x2go

# Admin account. Comment out to disable
ADMIN_USER="admin"
ADMIN_PASS="pass"

# Uncomment to change the default values for VNC.
#VNC_PASS="pass"
#VNC_PORT="5901"
#VNC_WIDTH="1024"
#VNC_HEIGHT="768"
#VNC_DEPTH="24"

# Access the server from the web with Guacamole
# https://guacamole.apache.org/doc/gug/using-guacamole.html
# It can be accessed on: https://$DOMAIN/guac/
# Comment out to disable installing Guacamole.
GUAC_ADMIN="admin"
GUAC_PASS="pass"
GUAC_USER_NAME="student"
GUAC_USER_PASS="student"

### SMTP server for sending notifications. You can build an SMTP server
### as described here:
### https://github.com/docker-scripts/postfix/blob/master/INSTALL.md
### Comment out if you don't have a SMTP server and want to use
### a gmail account (as described below).
SMTP_SERVER=smtp.example.org
SMTP_DOMAIN=example.org

### Gmail account for notifications. This will be used by ssmtp.
### You need to create an application specific password for your account:
### https://www.lifewire.com/get-a-password-to-access-gmail-by-pop-imap-2-1171882
#GMAIL_ADDRESS=vnc@example.org
#GMAIL_PASSWD=hdfhfdjkfglk
