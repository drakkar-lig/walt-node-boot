#!/bin/bash
eval "$(docker run waltplatform/dev-master env)"
THIS_DIR=$(cd $(dirname $0); pwd)
TMP_DIR=$(mktemp -d)
UBOOT_ARCHIVE_URL="ftp://ftp.denx.de/pub/u-boot/u-boot-2016.09.tar.bz2"
SVN_RPI_BOOT_FILES="https://github.com/raspberrypi/firmware/tags/1.20160620/boot"

cd "$THIS_DIR"
cp -rp builder_files/* $TMP_DIR

cd $TMP_DIR

cat > Dockerfile << EOF
FROM $DOCKER_RPI_BUILDER_IMAGE
MAINTAINER $DOCKER_IMAGE_MAINTAINER

# Download firmware files, keep the ones we need
RUN cd /opt && svn co -q $SVN_RPI_BOOT_FILES ./boot_files && \
    cd boot_files && \
    rm -rf .svn kernel*.img

# Download and extract u-Boot
RUN cd /opt && wget -q $UBOOT_ARCHIVE_URL && tar xfj u-boot* && \
    rm u-boot*.bz2 && mv u-boot* u-boot
WORKDIR /opt/u-boot

# create u-boot binary for rpi B+/B+
# name it kernel.img on the SD card
# (default name for rpi B/B+ when config.txt does not specify it)
RUN make rpi_defconfig && make && \
    cp u-boot.bin /opt/boot_files/kernel.img && \
    cp tools/mkimage /tmp && \
    make clean

# create u-boot binary for rpi 2 and rpi 3
# rpi_3_32b_defconfig works on both cards, thus
# we can name it kernel7.img on the SD card
# (default name for rpi 2 & 3 when config.txt does not specify it)
RUN make rpi_3_32b_defconfig && make && \
    cp u-boot.bin /opt/boot_files/kernel7.img && \
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
docker build -t "$DOCKER_RPI_BOOT_BUILDER_IMAGE" .
result=$?

rm -rf $TMP_DIR

exit $result


