#!/bin/sh

## We need to write the raw contents of the tar archive
## on the standard output by the end of the script 
## to send it to docker, hence in order for it 
## not to contain irrelevent messages produced 
## during the execution of the previous commands, 
## we need to temporarily disable stdout and stderr.

### Save stdout in file descriptor 6
exec 6>&1 
### Disable stdout & stderr redirecting them to null
exec >/dev/null 2>/dev/null

## We need to create the disk image containing 
## one partition with the ext4 file system,
## that occupies almost all the disk,
## as well as some unallocated space before it
## to store mbr partition scheme and 
## the grub, that can idetify this partition.


### Create empty disk disk.dd with the total
### size of 10MB, we skip 1 block of 10MB
### and copy (write) 0 input blocks,
### that creates empty file of 10MB,
### which actually allocates none of them,
### but the metadata. Since nothing is
### actually written, the proccess is instant.

dd of=disk.dd bs=10M seek=1 count=0

### Creating the partition table 

### Create a new empty DOS partition table (disklabel)
### Add a new partition
### Choose primary partition type for that partition
### Choose partiotion number
### Choose location of first sector of that partition (default 2048)
### Choose location of last sector of the partiotion (default 20479)
### Toggle a bootable flag on the partition
### Write partition table to disk and exit
fdisk disk.dd <<EOF
o
n
p
1


a
w
EOF

### Create empty disk disk.dd with the total
### size of 9MB, we skip 9 blocks of 1MB
### and copy (write) 0 input blocks,
### that creates empty file of 9MB,
### which actually allocates none of them,
### but the metadata. Since nothing is
### actually written, the proccess is instant.
dd of=part.dd bs=1M seek=9 count=0

### Create filesystem on the empty disk part.dd
### specifying the type ext4.
mkfs -t ext4 part.dd

### Copying part.dd disk into disk.dd disk
### starting from 1*1MB in disk.dd.
dd if=part.dd of=disk.dd bs=1M seek=1 conv=notrunc,sparse

mkdir part.mnt

### Mount the device disk.dd to the part.mnt directory
### specifying the start offset in bytes,
### so that only the partiotion of 9MB would be mounted.
mount -o offset=$((512*2048)) disk.dd part.mnt

cd /root/part.mnt/
mkdir -p grub/i386-pc/
cp /usr/lib/grub/i386-pc/* grub/i386-pc/

### Install GRUB to a device with heavy custom
### modifications, meaning breaking in two 
### more abstraguated command grub-install.

### Creating the bootable image of grub core.img 
### specifying the type i386-pc and the directory 
### with all the required modules.
grub-mkimage -O i386-pc -o grub/i386-pc/core.img -d grub/i386-pc -p "(hd0,msdos1)/grub" biosdisk part_msdos ext2

### Set up the device to boot using grub
### specifying the directory with images and modules.
grub-bios-setup -d ./grub/i386-pc/ ../disk.dd

mkdir ipxe && cp /usr/lib/ipxe/ipxe.lkrn ipxe/

### Creating custum grub configuration file
### without menu of timeout.

### Launching ipxe bootloader as it was an os
### and passing user-class as well as getting
### the ip address.
cat > grub/grub.cfg << EOF
set root='(hd0,msdos1)'
linux16 /ipxe/ipxe.lkrn set user-class walt.node.pc-x86-64 \&\& dhcp \&\& chain boot/pc-x86-64.ipxe \|\| reboot
boot
EOF

cd /root/
### Unmounting the partition
umount part.mnt

### Restore stdout from file descriptor 6
exec 1>&6

### Dump disk image to stdout
cat /root/disk.dd

