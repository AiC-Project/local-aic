FROM ubuntu:16.04

RUN apt-get -y update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y software-properties-common apt-utils && \
    dpkg --add-architecture i386 && \
    add-apt-repository multiverse && \
    add-apt-repository -y ppa:webupd8team/java && \
    add-apt-repository -y ppa:openjdk-r/ppa && \
    apt-get -y update && \
    (echo "debconf shared/accepted-oracle-license-v1-1 select true" | debconf-set-selections) && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        adduser \
        build-essential \
        bc \
        git \
        zip \
        flex \
        bison \
        gperf \
        libxml2-utils \
        libstdc++6:i386 \
        libgcc1:i386 \
        zlib1g:i386 \
        libncurses5:i386 \
        oracle-java6-installer \
        openjdk-7-jdk \
        virtualbox \
        curl \
        yasm && \
    apt-get clean -y && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN curl https://storage.googleapis.com/git-repo-downloads/repo -o /usr/local/bin/repo && \
    chmod a+x /usr/local/bin/repo

ENV archive "make-3.82.tar.gz"
ENV make_url "http://ftp.gnu.org/gnu/make/${archive}"
ENV build_dir "/root/make"
ENV sha256sum "3d991b33e604187c5881a0abc2e102d5b9776da5569640e73778f85d617242e7"

RUN mkdir $build_dir && \
    curl $make_url -o ${build_dir}/${archive} && \
    cd ${build_dir}/ && \
    echo '3d991b33e604187c5881a0abc2e102d5b9776da5569640e73778f85d617242e7  make-3.82.tar.gz' | sha256sum -c '-' && \
    /bin/tar --extract --gzip --strip-components=1 --file ${archive} && \
    ./configure && \
    make && \
    cp -a "${build_dir}/make" "/usr/local/bin/make-3.82"

ARG USER_ID
ARG GROUP_ID

RUN addgroup --gid $GROUP_ID developer
RUN adduser --uid $USER_ID --gid $GROUP_ID --disabled-login --gecos "" developer
USER developer
WORKDIR /home/developer

