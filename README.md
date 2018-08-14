# Desktop in a container

## Installation

  - First install `ds` and `wsproxy`:
     + https://github.com/docker-scripts/ds#installation
     + https://github.com/docker-scripts/wsproxy#installation

  - Then get the scripts from github: `ds pull desktop`

  - Create a directory for the container: `ds init desktop @desk.example.org`

  - Fix the settings: `cd /var/ds/desk.example.org/; vim settings.sh`

  - Build image, create the container and configure it: `ds make`


## Accessing

  - Tell `wsproxy` to manage the domain of this container: `ds wsproxy add`

  - Tell `wsproxy` to get a free letsencrypt.org SSL certificate for this domain (if it is a real one):
    ```
    ds wsproxy ssl-cert --test
    ds wsproxy ssl-cert
    ```

 - If the domain is not a real one, add to `/etc/hosts` the line:
    `123.45.67.89 desk.example.org`

 - Try in browser: http://desk.example.org?host=desk.example.org&port=6901


## Other commands

```
ds stop
ds start
ds shell
ds help
```
