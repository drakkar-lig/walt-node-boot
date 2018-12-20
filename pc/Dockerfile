FROM debian:stretch

# Making the process completely noninteractive
ENV DEBIAN_FRONTEND noninteractive
# Defining English as default language
ENV LANG C

# Installing essential apps
RUN apt-get update && \
    apt-get install -y gdisk dosfstools wget git make gcc \
    grub-efi-ia32-bin grub-efi-amd64-bin vim grub-pc liblzma-dev

# Add ipxe boot script
ADD boot.ipxe /root/

# Build 3 needed variants of ipxe
WORKDIR /root
RUN git clone git://git.ipxe.org/ipxe.git && cd ipxe && \
    git checkout 133f4c47baef6002b2ccb4904a035cda2303c6e5
RUN cd ipxe/src && make -j bin-x86_64-efi/ipxe.efi EMBED=/root/boot.ipxe
RUN cd ipxe/src && make -j bin-i386-efi/ipxe.efi EMBED=/root/boot.ipxe
RUN cd ipxe/src && make -j bin/ipxe.lkrn EMBED=/root/boot.ipxe

# Adding the entrypoint script to the image
ADD entry_point.sh /root/
