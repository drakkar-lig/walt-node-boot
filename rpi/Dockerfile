FROM debian:bullseye as builder
MAINTAINER Etienne Duble <etienne.duble@imag.fr>
ENV UBOOT_BZ2_ARCHIVE_URL='https://ftp.denx.de/pub/u-boot/u-boot-2023.10.tar.bz2'
ENV RPI_BOOTFILES_GIT_REPO='https://github.com/raspberrypi/firmware'
ENV RPI_BOOTFILES_GIT_COMMIT='a3b20e7dd41aa174ae50b872c8c9c66beafd63e2'
ENV RPI_EEPROM_SVN_URL='https://github.com/raspberrypi/rpi-eeprom'
ENV RPI4_EEPROM_FIRMWARE='firmware-2711/latest/pieeprom-2025-02-11.bin'
ENV RPI4_EEPROM_RECOVERY_BIN='firmware-2711/latest/recovery.bin'
ENV RPI5_EEPROM_FIRMWARE='firmware-2712/latest/pieeprom-2025-02-12.bin'
ENV RPI5_EEPROM_RECOVERY_BIN='firmware-2712/latest/recovery.bin'

# setup package management
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

# install packages
RUN apt-get update && apt-get upgrade -y && apt-get install -y \
    vim net-tools procps subversion make gcc g++ libncurses5-dev bzip2 \
    wget cpio python unzip bc kpartx dosfstools debootstrap debian-archive-keyring \
    git flex bison pkg-config zlib1g-dev libglib2.0-dev libgnutls28-dev \
    libpixman-1-dev gcc-arm-linux-gnueabi gcc-aarch64-linux-gnu libssl-dev kmod \
    dpkg-dev debhelper bash-completion shellcheck rdfind fdisk && \
    apt-get clean

# Download firmware files, keep the ones we need
RUN cd /opt && mkdir boot_files_download && cd boot_files_download && \
    git init && git remote add origin "$RPI_BOOTFILES_GIT_REPO" && \
    git fetch --depth 1 origin "$RPI_BOOTFILES_GIT_COMMIT" && \
    git checkout "$RPI_BOOTFILES_GIT_COMMIT" && \
    mv boot ../boot_files && cd ../boot_files && \
    rm -rf ../boot_files_download && \
    rm -rf kernel*.img \
           start*x.elf start*cd.elf start*db.elf \
           fixup*x.dat fixup*cd.dat fixup*db.dat

# Add static files to boot_files
ADD builder_files/config.txt /opt/boot_files
ADD builder_files/config-64.txt /opt/boot_files
ADD builder_files/cmdline.txt /opt/boot_files
ADD builder_files/README.walt /opt/boot_files

# Compile 32bit u-boot versions
RUN cd /opt && wget -q $UBOOT_BZ2_ARCHIVE_URL && tar xf u-boot* && \
                rm u-boot*.bz2 && mv u-boot* u-boot
WORKDIR /opt/u-boot
ADD builder_files/config.fragment .
ADD builder_files/config-debug.fragment .
ADD builder_files/compile-uboot.sh .

ENV ARCH=arm
ENV CROSS_COMPILE=arm-linux-gnueabi-

# patch u-boot for 32bit mode on rpi4 --
# u-boot hangs on rpi4 at SE when enumerating PCI devices.
# the same problem was found with the home assistant project, and
# they soved it by reverting a u-boot commit.
# https://github.com/home-assistant/operating-system/issues/2500
# https://github.com/home-assistant/operating-system/pull/2505/commits/1725030de7d7cf94fe38e8bdf4c52f2af766164f
# we do the same here.
ADD builder_files/pci-enumeration.patch /opt/u-boot/
RUN patch -i pci-enumeration.patch drivers/pci/pci-uclass.c

RUN ./compile-uboot.sh rpi-b rpi_defconfig -- cp tools/mkimage /tmp
RUN ./compile-uboot.sh rpi-2-b rpi_2_defconfig
RUN ./compile-uboot.sh rpi-3-b rpi_3_32b_defconfig
RUN ./compile-uboot.sh rpi-4-b rpi_4_32b_defconfig

# Compile 64bit u-boot versions
# As of now (february 2025) mainstream u-boot does not support
# network booting on the rpi5, so we will have to apply a patch
# and select a specific git commit where this patch applies well.
RUN cd /opt && git clone https://github.com/u-boot/u-boot u-boot-64b
WORKDIR /opt/u-boot-64b
RUN git checkout 6e316e3f397b5e01e98c5dd56cdbaab961daeedf
ADD builder_files/rpi5.patch .
ADD builder_files/config.fragment .
ADD builder_files/config-debug.fragment .
ADD builder_files/compile-uboot.sh .

ENV ARCH=arm64
ENV CROSS_COMPILE=aarch64-linux-gnu-

RUN ./compile-uboot.sh rpi-3-b-64b rpi_3_defconfig
RUN ./compile-uboot.sh rpi-4-b-64b rpi_4_defconfig
RUN git apply -v rpi5.patch && \
    ./compile-uboot.sh rpi-5-b rpi_arm64_defconfig

# prepare rpi4 & rpi5 eeprom update files
RUN cd /opt && git clone $RPI_EEPROM_SVN_URL ./rpi-eeprom && \
    cd rpi-eeprom && \
    rm -rf .git
WORKDIR /opt/rpi-eeprom
ADD builder_files/rpi-eeprom-auto-update.sh .
RUN mkdir /opt/recovery-rpi4 /opt/recovery-rpi5
RUN ./rpi-eeprom-auto-update.sh \
    $RPI4_EEPROM_FIRMWARE $RPI4_EEPROM_RECOVERY_BIN /opt/recovery-rpi4
RUN ./rpi-eeprom-auto-update.sh \
    $RPI5_EEPROM_FIRMWARE $RPI5_EEPROM_RECOVERY_BIN /opt/recovery-rpi5

# add release date file
RUN date > /opt/boot_files/walt.date && \
    date +%s >> /opt/boot_files/walt.date && \
    cp /opt/boot_files/walt.date /opt/recovery-rpi4/ && \
    cp /opt/boot_files/walt.date /opt/recovery-rpi5/

# install entry point
ADD builder_files/entrypoint.sh /entry_point.sh
ENTRYPOINT ["/entry_point.sh"]
CMD []

# set workdir to /opt/boot_files
WORKDIR /opt/boot_files
