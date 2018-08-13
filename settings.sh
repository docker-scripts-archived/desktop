APP=desktop

### Docker settings.
IMAGE=desktop
CONTAINER=desktop
DOMAIN="desk.example.org"
PORTS="5900:5900 6901:6901"

### VNC settings
#VNC_PW=pass123
VNC_DEPTH=24
VNC_WIDTH=1024
VNC_HEIGHT=768

### Gmail account for notifications. This will be used by ssmtp.
### You need to create an application specific password for your account:
### https://www.lifewire.com/get-a-password-to-access-gmail-by-pop-imap-2-1171882
GMAIL_ADDRESS=vnc@example.org
GMAIL_PASSWD=hdfhfdjkfglk
