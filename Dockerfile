FROM ubuntu:18.04
LABEL maintainer="Chef Software, Inc. <docker@chef.io>"

ARG VERSION=4.41.20
ARG CHANNEL=stable

ENV PATH=/opt/dynamo/bin:/opt/dynamo/embedded/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Run the entire container with the default locale to be en_US.UTF-8
RUN apt-get update && \
    apt-get install -y locales && \
    locale-gen en_US.UTF-8 && \
    update-locale LANG=en_US.UTF-8 && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8


RUN mkdir -p /share

RUN apt-get update && \
    apt-get install -y wget rpm2cpio cpio && \
    wget "http://packages.chef.io/files/${CHANNEL}/dynamo/${VERSION}/el/7/dynamo-${VERSION}-1.el7.x86_64.rpm" -O /tmp/dynamo.rpm && \
    rpm2cpio /tmp/dynamo.rpm | cpio -idmv && \
    rm -rf /tmp/dynamo.rpm

# Install any packages that make life easier for an Dynamo installation
RUN apt-get install -y git

ENTRYPOINT ["dynamo"]
CMD ["help"]
VOLUME ["/share"]
WORKDIR /share
