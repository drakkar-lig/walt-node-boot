FROM debian:trixie

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
RUN git clone https://github.com/ipxe/ipxe.git && cd ipxe && \
    git checkout v2.0.0
WORKDIR /root/ipxe/src
RUN nice make -j $(nproc) bin/undionly.kpxe EMBED=/root/boot.ipxe
RUN nice make -j $(nproc) bin-x86_64-efi/snponly.efi EMBED=/root/boot.ipxe

# Adding the entrypoint script to the image
ADD entry_point.sh /root/
