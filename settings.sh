APP=desktop

### Docker settings.
IMAGE=desktop
CONTAINER=desktop
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

### Gmail account for notifications. This will be used by ssmtp.
### You need to create an application specific password for your account:
### https://www.lifewire.com/get-a-password-to-access-gmail-by-pop-imap-2-1171882
#GMAIL_ADDRESS=vnc@example.org
#GMAIL_PASSWD=hdfhfdjkfglk
