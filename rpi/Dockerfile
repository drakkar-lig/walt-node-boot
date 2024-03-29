FROM debian:bullseye as builder
MAINTAINER Etienne Duble <etienne.duble@imag.fr>
ENV UBOOT_BZ2_ARCHIVE_URL='https://ftp.denx.de/pub/u-boot/u-boot-2023.10.tar.bz2'
ENV RPI_BOOTFILES_GIT_REPO='https://github.com/raspberrypi/firmware'
ENV RPI_BOOTFILES_GIT_COMMIT='a3b20e7dd41aa174ae50b872c8c9c66beafd63e2'
ENV RPI_EEPROM_SVN_URL='https://github.com/raspberrypi/rpi-eeprom'
ENV RPI_EEPROM_FIRMWARE='firmware-2711/latest/pieeprom-2023-05-11.bin'
ENV RPI_EEPROM_RECOVERY_BIN='firmware-2711/latest/recovery.bin'

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
RUN cd /opt && mkdir boot_files_download && cd boot_files_download && \
    git init && git remote add origin "$RPI_BOOTFILES_GIT_REPO" && \
    git fetch --depth 1 origin "$RPI_BOOTFILES_GIT_COMMIT" && \
    git checkout "$RPI_BOOTFILES_GIT_COMMIT" && \
    mv boot ../boot_files && cd ../boot_files && \
    rm -rf ../boot_files_download && \
    rm -rf kernel*.img \
           start*x.elf start*cd.elf start*db.elf \
           fixup*x.dat fixup*cd.dat fixup*db.dat

# Add config.txt & cmdline.txt
ADD builder_files/config.txt /opt/boot_files
ADD builder_files/cmdline.txt /opt/boot_files

WORKDIR /opt/u-boot
ADD builder_files/config.fragment .

ENV ARCH=arm
ENV CROSS_COMPILE=arm-linux-gnueabi-

# patch u-boot --
# u-boot hangs on rpi4 at SE when enumerating PCI devices.
# the same problem was found with the home assistant project, and
# they soved it by reverting a u-boot commit.
# https://github.com/home-assistant/operating-system/issues/2500
# https://github.com/home-assistant/operating-system/pull/2505/commits/1725030de7d7cf94fe38e8bdf4c52f2af766164f
# we do the same here.
ADD builder_files/pci-enumeration.patch /opt/u-boot/
RUN patch -i pci-enumeration.patch drivers/pci/pci-uclass.c

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
