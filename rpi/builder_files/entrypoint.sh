#!/bin/bash
set -e

rpi_series="$1"
if [ "$rpi_series" = "old" ]
then
    # old models need the whole set of files
    tar cfz - .
elif [ "$rpi_series" = "rpi4" -o "$rpi_series" = "rpi5" ]
then
    # rpi4 & rpi5 just need to be booted once with a SD card
    # containing appropriate "recovery" files to set network
    # boot 1st in the boot order.
    cd "/opt/recovery-${rpi_series}"
    tar cfz - .
else
    echo "Unexpected argument: {rpi_series}" >&2
    exit 1
fi
