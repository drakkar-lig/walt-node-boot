FROM debian:bullseye as builder
MAINTAINER Etienne Duble <etienne.duble@imag.fr>
ENV UBOOT_BZ2_ARCHIVE_URL='ftp://ftp.denx.de/pub/u-boot/u-boot-2022.01.tar.bz2'
ENV RPI_BOOTFILES_SVN_URL='https://github.com/raspberrypi/firmware/tags/1.20220120/boot'
ENV RPI_EEPROM_SVN_URL='https://github.com/raspberrypi/rpi-eeprom'
ENV RPI_EEPROM_FIRMWARE='firmware/stable/pieeprom-2022-02-08.bin'
ENV RPI_EEPROM_RECOVERY_BIN='firmware/stable/recovery.bin'

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

# Download firmware files, keep the ones we need
RUN cd /opt && svn co -q $RPI_BOOTFILES_SVN_URL ./boot_files && \
    cd boot_files && \
    rm -rf .svn kernel*.img

# Add config.txt & cmdline.txt
ADD builder_files/config.txt /opt/boot_files
ADD builder_files/cmdline.txt /opt/boot_files

WORKDIR /opt/u-boot
ADD builder_files/config.fragment .

ENV ARCH=arm
ENV CROSS_COMPILE=arm-linux-gnueabi-

# create u-boot binary for rpi b and b+
RUN make rpi_defconfig && \
    ./scripts/kconfig/merge_config.sh .config config.fragment && \
    make -j $(nproc) && \
    cp u-boot.bin /opt/boot_files/u-boot-rpi-b.img && \
    cp tools/mkimage /tmp && \
    make clean

# create u-boot binary for rpi 2b
RUN make rpi_2_defconfig && \
    ./scripts/kconfig/merge_config.sh .config config.fragment && \
    make -j $(nproc) && \
    cp u-boot.bin /opt/boot_files/u-boot-rpi-2-b.img && \
    make clean

# create u-boot binary for rpi 3b and 3b+
RUN make rpi_3_32b_defconfig && \
    ./scripts/kconfig/merge_config.sh .config config.fragment && \
    make -j $(nproc) && \
    cp u-boot.bin /opt/boot_files/u-boot-rpi-3-b.img && \
    make clean

# create u-boot binary for rpi 4
RUN make rpi_4_32b_defconfig && \
    ./scripts/kconfig/merge_config.sh .config config.fragment && \
    make -j $(nproc) && \
    cp u-boot.bin /opt/boot_files/u-boot-rpi-4-b.img && \
    make clean

# create u-boot startup script
ADD builder_files/boot.scr.txt /tmp
RUN /tmp/mkimage -A arm -O linux -T script -C none -n boot.scr \
         -d /tmp/boot.scr.txt /opt/boot_files/boot.scr.uimg

# prepare rpi4 eeprom auto-update files
RUN cd /opt && git clone $RPI_EEPROM_SVN_URL ./rpi-eeprom && \
    cd rpi-eeprom && \
    rm -rf .git
WORKDIR /opt/rpi-eeprom
ADD builder_files/rpi-eeprom-auto-update.sh .
RUN ./rpi-eeprom-auto-update.sh \
    $RPI_EEPROM_FIRMWARE $RPI_EEPROM_RECOVERY_BIN /opt/boot_files

# add release date file
RUN date > /opt/boot_files/walt.date && \
    date +%s >> /opt/boot_files/walt.date

# install entry point
ADD builder_files/create_and_dump_sd_image.sh /entry_point.sh
ENTRYPOINT ["/entry_point.sh"]
CMD []

# set workdir to /opt/boot_files
WORKDIR /opt/boot_files
