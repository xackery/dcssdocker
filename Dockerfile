FROM ubuntu:18.04

# create a S3 bucket in aws
ENV AWS_ACCESS_KEY=acceskey
ENV AWS_SECRET_ACCESS_KEY=secret
ENV S3_BUCKET_NAME=bucketname
ENV SMTP_USERNAME=username@gmail.com
ENV SMTP_PASSWORD=password

ARG USERNAME=dcss
ARG USER_UID=1000
ARG USER_GID=$USER_UID

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \ 
    && apt-get -y install --no-install-recommends apt-utils dialog 2>&1 \
    #
    # Verify git, process tools installed
    && apt-get -y install git openssh-client less iproute2 procps \
    && apt-get update \
    #
    # Create a non-root user to use
    && groupadd --gid $USER_GID $USERNAME \
    && useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USERNAME \
    # [Optional] Add sudo support for the non-root user
    && apt-get install -y sudo \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME\
    && chmod 0440 /etc/sudoers.d/$USERNAME \
    # install essentials
    && apt-get update \
    && apt-get -y install --no-install-recommends build-essential \
    gcc-5 g++-5 libtool cmake curl debconf-utils \
    git git-core \
    minizip make locales \
    nano unzip iputils-ping \
    zlibc wget \
    python3 python3-pip python3-setuptools libpq-dev python3-dev python3-venv python3-wheel \
    libfuse-dev libcurl4-openssl-dev libxml2-dev pkg-config libssl-dev mime-support automake libtool wget tar git unzip lsb-release groff less \
    libpng-dev libncursesw5-dev bison flex libsqlite3-dev libz-dev pkg-config python3-yaml binutils-gold \
    libsdl2-image-dev libsdl2-mixer-dev libsdl2-dev \
    libfreetype6-dev libpng-dev ttf-dejavu-core advancecomp pngcrush \
    # Clean up
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

# fix locales
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
    && dpkg-reconfigure --frontend=noninteractive locales \
    && update-locale LANG=en_US.UTF-8
ENV DEBIAN_FRONTEND=dialog
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8

# prepare dcss
RUN python3 -m pip install pyyaml
RUN pip3 install wheel
RUN git clone --recurse-submodules https://github.com/crawl/crawl.git /dcss/
RUN cd /dcss/crawl-ref/source && ls && make -j4 WEBTILES=y USE_DGAMELAUNCH=y

# prepare dcss webserver
RUN cd /dcss/crawl-ref/source && pip3 install -r webserver/requirements/dev.py3.txt
COPY config.py /dcss/crawl-ref/source/webserver/config.py 

# set up aws mount
RUN pip3 --no-cache-dir install --upgrade awscli
RUN rm -rf /usr/src/s3fs-fuse
RUN git clone https://github.com/s3fs-fuse/s3fs-fuse/ /usr/src/s3fs-fuse
WORKDIR /usr/src/s3fs-fuse 
RUN ./autogen.sh && ./configure && make && make install
RUN mkdir -p /mnt/s3/
ENV S3_MOUNT_DIRECTORY=/mnt/s3
RUN echo $AWS_ACCESS_KEY:$AWS_SECRET_ACCESS_KEY > /root/.passwd-s3fs && \
    chmod 600 /root/.passwd-s3fs

WORKDIR /
ADD start.sh /start.sh
RUN chmod 755 /start.sh
CMD ["/start.sh"]