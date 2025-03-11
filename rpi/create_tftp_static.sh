#!/bin/bash

FILES="""
./bcm2710-rpi-3-b.dtb
./bcm2710-rpi-3-b-plus.dtb
./bcm2711-rpi-400.dtb
./bcm2711-rpi-4-b.dtb
./bcm2712-rpi-5-b.dtb
./bootcode.bin
./cmdline.txt
./config.txt
./COPYING.linux
./fixup4.dat
./fixup.dat
./LICENCE.broadcom
./overlays
./start4.elf
./start.elf
./u-boot-rpi-3-b.img
./u-boot-rpi-4-b.img
./u-boot-rpi-5-b.img
./walt.date
"""

set -e -x
project_dir="$(pwd)"
temp_dir="$(mktemp -d)"
archive_dir="$temp_dir/tftp-static"
trap "cd; rm -rf $temp_dir" EXIT

mkdir $archive_dir
cd $archive_dir
tar xfz "$project_dir/build/rpi-sd-files.tar.gz" $FILES
# if we update tftp-static.tar.gz in walt-server, we will have to update
# the time reference in the source code too, so copy walt.date in the build
# directory for easy access. 
cp walt.date "$project_dir/build/"
cd ..
tar cf "tftp-static.tar" tftp-static
gzip --best < "tftp-static.tar" > "$project_dir/build/tftp-static.tar.gz"
