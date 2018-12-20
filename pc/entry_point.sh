#!/bin/sh

## We need to write the raw contents of the tar archive
## on the standard output by the end of the script 
## to send it to docker, hence in order for it 
## not to contain irrelevent messages produced 
## during the execution of the previous commands, 
## we need to temporarily disable stdout.

### Save stdout in file descriptor 6
exec 6>&1 
### Disable stdout & stderr redirecting them to null
exec >/dev/null 2>/dev/null

### Create empty disk disk.dd
dd of=disk.dd bs=25M seek=1 count=0

### Create the partition table 
# * 1: 12MiB, EFI partition 
# * 2: 1MiB, Bios boot partition 
# * 3: 8MiB, "linux-type" partition 
sgdisk \
    -n 1:1M:13M  -t 1:ef00 \
    -n 2:14M:15M -t 2:ef02 \
    -n 3:16M:24M -t 3:8e00  disk.dd

### Setup partition 3.
# We will start with an empty file that will
# copy at the right offset of disk.dd
dd of=part3.dd bs=1M seek=8 count=0
# filesystem
mkfs -t ext4 part3.dd
dd if=part3.dd of=disk.dd bs=1M seek=16 conv=notrunc,sparse
# mount
mkdir part3.mnt
mount -o offset=$((16*1024*1024)) disk.dd part3.mnt
# install grub
cd /root/part3.mnt/
mkdir -p grub/i386-pc/
cp /usr/lib/grub/i386-pc/* grub/i386-pc/
grub-mkimage -O i386-pc -o grub/i386-pc/core.img -d grub/i386-pc \
            -p "(hd0,gpt3)/grub" biosdisk part_gpt ext2
grub-bios-setup -d ./grub/i386-pc/ ../disk.dd
# install ipxe
mkdir ipxe && cp /root/ipxe/src/bin/ipxe.lkrn ipxe/
# configure grub
cat > grub/grub.cfg << EOF
set root='(hd0,gpt3)'
linux16 /ipxe/ipxe.lkrn
boot
EOF
# cleanup
cd /root/
umount part3.mnt

### Setup partition 1.
dd of=part1.dd bs=1M seek=12 count=0
# filesystem
mkfs -t vfat part1.dd
dd if=part1.dd of=disk.dd bs=1M seek=1 conv=notrunc,sparse
# mount
mkdir part1.mnt
mount -o offset=$((1*1024*1024)) disk.dd part1.mnt
# copy efi ipxe images
mkdir -p part1.mnt/EFI/BOOT/
cp /root/ipxe/src/bin-i386-efi/ipxe.efi part1.mnt/EFI/BOOT/BOOTIA32.efi && \
cp /root/ipxe/src/bin-x86_64-efi/ipxe.efi part1.mnt/EFI/BOOT/BOOTX64.efi
# cleanup
umount part1.mnt

### Restore stdout from file descriptor 6
exec 1>&6

### Dump disk image to stdout
cat /root/disk.dd

