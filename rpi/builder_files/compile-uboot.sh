#!/bin/sh
set -x -e

model="$1"
defconfig="$2"
if [ "$3" = "--" ]
then
    shift 3
    other_cmd="$@"
else
    other_cmd=""
fi

# compile normal version
make ${defconfig}
./scripts/kconfig/merge_config.sh .config config.fragment
make -j $(nproc)
cp u-boot.bin /opt/boot_files/u-boot-${model}.img

# tune config and compile debug version
./scripts/kconfig/merge_config.sh .config config-debug.fragment
make -j $(nproc)
cp u-boot.bin /opt/boot_files/u-boot-${model}-debug.img && \

# run other command if provided before cleaning up
if [ ! -z "$other_cmd" ]
then
    $other_cmd
fi

# clean up
make clean
