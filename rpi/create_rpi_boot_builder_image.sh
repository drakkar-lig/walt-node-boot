#!/bin/bash
UBOOT_BZ2_ARCHIVE_URL='ftp://ftp.denx.de/pub/u-boot/u-boot-2020.07.tar.bz2'
RPI_BOOTFILES_SVN_URL='https://github.com/raspberrypi/firmware/tags/1.20200723/boot'

THIS_DIR=$(cd $(dirname $0); pwd)
TMP_DIR=$(mktemp -d)

cd "$THIS_DIR"
cp -rp builder_files/* $TMP_DIR

cd $TMP_DIR

cat > Dockerfile << EOF
FROM debian:bullseye as builder
MAINTAINER Etienne Duble <etienne.duble@imag.fr>

# setup package management
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

# install packages
RUN apt-get update && apt-get upgrade -y && apt-get install -y \
    vim net-tools procps subversion make gcc g++ libncurses5-dev bzip2 \
    wget cpio python unzip bc kpartx dosfstools debootstrap debian-archive-keyring \
    git flex bison pkg-config zlib1g-dev libglib2.0-dev \
    libpixman-1-dev gcc-arm-linux-gnueabi gcc-aarch64-linux-gnu libssl-dev kmod \
    dpkg-dev debhelper bash-completion shellcheck rdfind fdisk && \
    apt-get clean

# Download and extract u-Boot source in /opt/u-boot
RUN cd /opt && wget -q $UBOOT_BZ2_ARCHIVE_URL && tar xf u-boot* && \
                rm u-boot*.bz2 && mv u-boot* u-boot
# Add the fix for rpi4 ethernet driver (not upstreamed yet)
ADD bcmgenet.c /opt/u-boot/drivers/net/

# Download firmware files, keep the ones we need
RUN cd /opt && svn co -q $RPI_BOOTFILES_SVN_URL ./boot_files && \
    cd boot_files && \
    rm -rf .svn kernel*.img

# Add config.txt & cmdline.txt
ADD config.txt /opt/boot_files
ADD cmdline.txt /opt/boot_files

WORKDIR /opt/u-boot

ENV ARCH=arm
ENV CROSS_COMPILE=arm-linux-gnueabi-

# create u-boot binary for rpi b and b+
RUN make rpi_defconfig && make -j && \
    cp u-boot.bin /opt/boot_files/kernel-rpi-b.img && \
    cp tools/mkimage /tmp && \
    make clean

# create u-boot binary for rpi 2b
RUN make rpi_2_defconfig && make -j && \
    cp u-boot.bin /opt/boot_files/kernel-rpi-2-b.img && \
    make clean

# create u-boot binary for rpi 3b and 3b+
RUN make rpi_3_32b_defconfig && make -j && \
    cp u-boot.bin /opt/boot_files/kernel-rpi-3-b.img && \
    make clean

# create u-boot binary for rpi 4
RUN make rpi_4_32b_defconfig && make -j && \
    cp u-boot.bin /opt/boot_files/kernel-rpi-4-b.img && \
    make clean

# create u-boot startup script
ADD boot.scr.txt /tmp
RUN /tmp/mkimage -A arm -O linux -T script -C none -n boot.scr \
         -d /tmp/boot.scr.txt /opt/boot_files/boot.scr.uimg

# add release date file
RUN date > /opt/boot_files/walt.date && \
    date +%s >> /opt/boot_files/walt.date

# install entry point
ADD create_and_dump_sd_image.sh /entry_point.sh
ENTRYPOINT ["/entry_point.sh"]
CMD []

# set workdir to /opt/boot_files
WORKDIR /opt/boot_files

EOF
docker build -t "waltplatform/rpi-boot-builder" .
result=$?

rm -rf $TMP_DIR

exit $result


