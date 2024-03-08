FROM debian:bullseye

# Making the process completely noninteractive
ENV DEBIAN_FRONTEND noninteractive
# Defining English as default language
ENV LANG C

# Installing essential apps
RUN apt-get update && \
    apt-get install -y wget git make gcc \
    vim liblzma-dev extlinux

# Add ipxe boot script
ADD boot.ipxe /root/

# Build ipxe with linux kernel image format
WORKDIR /root
RUN git clone git://git.ipxe.org/ipxe.git && cd ipxe && \
    git checkout d79f504c0c390d40de3d27546ab27bc44b03516c
RUN cd ipxe/src && make -j bin/undionly.kpxe EMBED=/root/boot.ipxe

# Adding the entrypoint script to the image
ADD entry_point.sh /root/
