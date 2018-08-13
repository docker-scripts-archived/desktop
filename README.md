# Minimal Ubuntu container

## Installation

  - First install `ds`: https://github.com/docker-scripts/ds#installation

  - Then get the scripts from github: `ds pull ubuntu`

  - Create a directory for the container: `ds init ubuntu @ubuntu1`

  - Fix the settings: `cd /var/ds/ubuntu1/ ; vim settings.sh`

  - Build image, create the container and configure it: `ds make`

## Other commands

```
ds stop
ds start
ds shell
ds help
```
