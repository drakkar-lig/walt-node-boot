#!/bin/bash
rpi_eeprom_firmware="$1"
rpi_eeprom_recovery_bin="$2"
out_dir="$3"

# Try network first, then SD card, and repeat.
# read right to left, and see:
# https://www.raspberrypi.com/documentation/computers/raspberry-pi.html#BOOT_ORDER
BOOT_ORDER=0xf12

# For some reason, DHCP requests always seem to fail twice and succeed on the 3rd time.
# This is visible:
# - in u-boot trace
# - when enabling relative line timestamps in minicom, we see that the rpi firmware
#   also pauses 8 seconds before getting DHCP data, which corresponds to 2 failed DHCP
#   attempts with the default DHCP_REQ_TIMEOUT value of 4 seconds.
# So we reduce DHCP_REQ_TIMEOUT to its minimum value of 500 milliseconds (this reduces
# the pause in the firmware trace to 1 second only).

# Retrieve boot config embedded in firmware
cat > /tmp/bootconf.txt << EOF
[all]
BOOT_UART=1
BOOT_ORDER=${BOOT_ORDER}
DHCP_REQ_TIMEOUT=500
EOF

# Set this config in a copy of initial firmware and place it in $out_dir
# (see https://www.raspberrypi.com/documentation/computers/raspberry-pi.html#bootloader-update-files)
./rpi-eeprom-config --out "$out_dir/pieeprom.bin" \
                    --config /tmp/bootconf.txt "$rpi_eeprom_firmware"

# Add checksum file
sha256sum "$out_dir/pieeprom.bin" | awk '{print $1}' > "$out_dir/pieeprom.sig"
echo "ts: $(date -u +%s)" >> "$out_dir/pieeprom.sig"

# Copy recovery.bin to trigger the update on the first rpi4 boot
cp "$rpi_eeprom_recovery_bin" "$out_dir/recovery.bin"
