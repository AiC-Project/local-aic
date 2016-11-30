# Using the GPU for the rendering

The official docker images use
[mesa’s llvmpipe renderer](http://www.mesa3d.org/llvmpipe.html) in order
to have a fully isolated OpenGL rendering process. This allows AiC to ignore
system specificities and run without issues anywhere. However, its performance
is quite limited even on powerful CPUs and it is therefore useful to use a
graphics card (even an intel integrated one) to avoid that bottleneck, which
gets worse the more AiC virtual machines you are running.

To use the host graphics card while still displaying content in a
containerized X server, we use [VirtualGL](http://www.virtualgl.org/)
and the `vglrun` tool it includes.

To this end, the "sdl" container needs to share the X11 socket (which is
usually in `/tmp/.X11-unix`) from the host, and the linux rendering device
(see the nvidia compose file at the bottom of this page as an example).

The scripts also have to be changed in order to run the software through
vglrun, which is done in the start_sdl script as an example.
Usually it is enough to prefix the commands with (where `:0` is the host
X server to use for rendering)

```
vglrun -c 0 -d :0
```

Please note that this could be a security breach if an attacker takes control
of your AiC virtual device and finds a way to control the "sdl" container, as X
security and isolation is notorious for not existing.

## Mesa

### Dockerfile

You need to add the relevant mesa drivers to the list of packages to
install in the container image. This is setup-specific so we will
not cover it here.

You also need to install virtualgl, which is not in the official ubuntu
repos, so you need to download the [latest deb](https://sourceforge.net/projects/virtualgl/files/)
and install it inside the Dockerfile.

```Dockerfile
COPY virtualgl_2.X_amd64.deb /tmp/virtualgl_2.X_amd64.deb
RUN dpkg -i /tmp/virtualgl_2.X_amd64.deb
```

### Docker-compose

You will need to change the docker-compose file in order to share the
X server socket from the host in a read/write volume to the "sdl" container:

```yaml
  sdl:
    …
    volumes:
      …
      - /tmp/.X11-unix/:/tmp/.X11-unix/:rw
```

And you will need to share /dev/dri/card0 (or not card0, depending on
your setup):

```yaml
sdl:
    …
    devices:
      - /dev/dri/card0
```

## Nvidia

### Dockerfile

You need to start from the
[nvidia-docker opengl Dockerfile](https://github.com/NVIDIA/nvidia-docker/blob/opengl/ubuntu-14.04/opengl/virtualgl/Dockerfile),
tagged opengl:virtualgl (but based on ubuntu 16.04, not 14.04), then
copy the sdl.Dockerfile and the start_sdl into the src/player directory,
and do a source build to recreate the container images.

### docker-compose

The easiest way is to install the
[nvidia-docker plugin](https://github.com/NVIDIA/nvidia-docker)
(needs a docker restart) and replace the run-player.yml file in
lib/docker/ with the following:

```yaml
version: "2"

services:
  xorg:
    container_name: "${AIC_AVM_PREFIX}xorg"
    restart: unless-stopped
    image: aic.xorg
    ports:
      - 5900
    environment:
      - AIC_PLAYER_VNC_SECRET
      - AIC_PLAYER_MAX_DIMENSION
  ffserver:
    container_name: "${AIC_AVM_PREFIX}ffserver"
    restart: unless-stopped
    image: aic.ffserver
    ports:
      - 8090
  adb:
    container_name: "${AIC_AVM_PREFIX}adb"
    restart: unless-stopped
    image: aic.adb
    volumes_from:
      - container:${AIC_PROJECT_PREFIX}prjdata:ro
    environment:
      - AIC_PLAYER_VM_HOST
  sdl:
    container_name: "${AIC_AVM_PREFIX}sdl"
    restart: unless-stopped
    devices:
      - /dev/nvidia0
      - /dev/nvidiactl
      - /dev/nvidia-uvm
    image: aic.sdl
    volumes:
      - /tmp/.X11-unix:/tmp/.X11-unix:rw
      - nvidia_driver_370.28:/usr/local/nvidia:ro
    volumes_from:
      - avmdata
    # command: tail -f /dev/null
    environment:
      - AIC_PLAYER_AMQP_HOST
      - AIC_PLAYER_AMQP_USERNAME
      - AIC_PLAYER_AMQP_PASSWORD
      - AIC_PLAYER_VM_ID
      - AIC_PLAYER_VM_HOST
      - AIC_PLAYER_WIDTH
      - AIC_PLAYER_HEIGHT
      - AIC_PLAYER_DPI
      - AIC_PLAYER_ENABLE_RECORD
      - AIC_PLAYER_ANDROID_VERSION
      - AIC_PLAYER_PATH_RECORD
    # to be able to strace
    privileged: false
    depends_on:
      - xorg
    networks:
      - default
      - services_default
    external_links:
      - rabbitmq:rabbitmq
  audio:
    # command: tail -f /dev/null
    container_name: "${AIC_AVM_PREFIX}audio"
    restart: unless-stopped
    image: aic.audio
    environment:
      - AIC_PLAYER_VM_HOST
    depends_on:
      - ffserver
    networks:
      - default
      - services_default
    external_links:
      - rabbitmq:rabbitmq
  sensors:
    # command: tail -f /dev/null
    container_name: "${AIC_AVM_PREFIX}sensors"
    restart: unless-stopped
    image: aic.sensors
    environment:
      - AIC_PLAYER_AMQP_HOST
      - AIC_PLAYER_AMQP_USERNAME
      - AIC_PLAYER_AMQP_PASSWORD
      - AIC_PLAYER_VM_HOST
      - AIC_PLAYER_VM_ID
      - AIC_PLAYER_ENABLE_SENSORS
      - AIC_PLAYER_ENABLE_BATTERY
      - AIC_PLAYER_ENABLE_GPS
      - AIC_PLAYER_ENABLE_GSM
      - AIC_PLAYER_ENABLE_NFC
    networks:
      - default
      - services_default
    external_links:
      - rabbitmq:rabbitmq
  camera:
    # command: tail -f /dev/null
    container_name: "${AIC_AVM_PREFIX}camera"
    restart: unless-stopped
    image: aic.camera
    environment:
      - AIC_PLAYER_AMQP_HOST
      - AIC_PLAYER_AMQP_USERNAME
      - AIC_PLAYER_AMQP_PASSWORD
      - AIC_PLAYER_VM_HOST
      - AIC_PLAYER_VM_ID
    volumes_from:
      - container:${AIC_PROJECT_PREFIX}prjdata:ro
    networks:
      - default
      - services_default
    external_links:
      - rabbitmq:rabbitmq
  avmdata:
    container_name: "${AIC_AVM_PREFIX}avmdata"
    restart: unless-stopped
    image: aic.avmdata
    volumes:
      - /data/avm
    networks: []

networks:
  services_default:
    external: true
  default:

volumes:
  nvidia_driver_370.28:
    external: true
```
