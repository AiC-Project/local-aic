FROM opengl:virtualgl

# need to wipe those variables otherwise things will panic while building
ENV LD_PRELOAD ""
ENV LD_LIBRARY_PATH ""

RUN apt-get -y update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        busybox \
        strace \
        telnet \
        net-tools \
        iputils-ping \
        mtr \
        amqp-tools \
        libav-tools \
        libavcodec-ffmpeg56 \
        libavformat-ffmpeg56 \
        libsdl2-2.0 \
        libswscale-ffmpeg3 \
        libglib2.0-0 \
        libxv1 \
        libpopt0 \
        libprotobuf-c1 \
        librabbitmq4 \
        mesa-utils \
        libasan2 && \
    apt-get clean -y && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN useradd -m developer

COPY ./sdl/out/player_sdl_grab /home/developer/sdl_sensor_broker/
COPY ./sdl/lib /home/developer/sdl_sensor_broker/lib
COPY ./start_sdl /home/developer/start_sdl

RUN chown -R developer.developer /home/developer

USER developer

WORKDIR /home/developer/sdl_sensor_broker

ENV DISPLAY xorg:0.0
ENV LD_LIBRARY_PATH /usr/local/nvidia/lib:/usr/local/nvidia/lib64:${LD_LIBRARY_PATH}
ENV LD_PRELOAD /opt/nvidia/lib/x86_64-linux-gnu/libGL.so.1:${LD_PRELOAD}

CMD sh /home/developer/start_sdl

