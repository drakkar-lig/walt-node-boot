#!/bin/sh

# Dump to stdout
if [ "$1" = "undionly.kpxe" ]
then
    cat /root/ipxe/src/bin/undionly.kpxe
elif [ "$1" = "snponly.efi" ]
then
    cat /root/ipxe/src/bin-x86_64-efi/snponly.efi
fi
