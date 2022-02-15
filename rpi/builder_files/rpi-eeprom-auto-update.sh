#!/bin/bash
rpi_eeprom_firmware="$1"
rpi_eeprom_recovery_bin="$2"
out_dir="$3"

# Try SD card first, then network, and repeat.
# read right to left, and see:
# https://www.raspberrypi.com/documentation/computers/raspberry-pi.html#BOOT_ORDER
BOOT_ORDER=0xf21

# Retrieve boot config embedded in firmware
./rpi-eeprom-config "$rpi_eeprom_firmware" > /tmp/bootconf.txt

# Update BOOT_ORDER in this config
if grep -q "BOOT_ORDER=" /tmp/bootconf.txt
then
    # replace BOOT_ORDER with the value we want
    sed -i -e "s/BOOT_ORDER=.*/BOOT_ORDER=$BOOT_ORDER/" /tmp/bootconf.txt
else
    # BOOT_ORDER not defined yet, insert after first end-of-line   
    sed -i -e "0,/$/s//\nBOOT_ORDER=$BOOT_ORDER/" /tmp/bootconf.txt
fi

# Set this config in a copy of initial firmware and place it in $out_dir
# Note: the fact we call it pieeprom.upd and not pieeprom.bin allows
# to automate the reboot after the eeprom is flashed (see
# https://www.raspberrypi.com/documentation/computers/raspberry-pi.html#eeprom-update-files)
./rpi-eeprom-config --out "$out_dir/pieeprom.upd" \
                    --config /tmp/bootconf.txt "$rpi_eeprom_firmware"

# Add checksum file
sha256sum "$out_dir/pieeprom.upd" | awk '{print $1}' > "$out_dir/pieeprom.sig"
echo "ts: $(date -u +%s)" >> "$out_dir/pieeprom.sig"

# Copy recovery.bin to trigger the update on the first rpi4 boot
cp "$rpi_eeprom_recovery_bin" "$out_dir/recovery.bin"
