
all: build/rpi-sd-files.tar.gz build/rpi-4-sd-netboot.tar.gz build/rpi-5-sd-netboot.tar.gz build/tftp-static.tar.gz build/pc-usb.dd.gz build/walt-x86-undionly.kpxe

# archive of SD-card files for enabling network boot on a raspberry pi 5
build/rpi-5-sd-netboot.tar.gz: .date_files/rpi_boot_builder_image
	@mkdir -p build
	@docker run --rm waltplatform/rpi-boot-builder rpi5 > build/rpi-5-sd-netboot.tar.gz

# archive of SD-card files for enabling network boot on a raspberry pi 4
build/rpi-4-sd-netboot.tar.gz: .date_files/rpi_boot_builder_image
	@mkdir -p build
	@docker run --rm waltplatform/rpi-boot-builder rpi4 > build/rpi-4-sd-netboot.tar.gz

# archive of SD-card files for older generation Raspberry pi boards
build/rpi-sd-files.tar.gz: .date_files/rpi_boot_builder_image
	@mkdir -p build
	@docker run --rm waltplatform/rpi-boot-builder old > build/rpi-sd-files.tar.gz

# archive of files to be served by the walt server as part of new device handling
build/tftp-static.tar.gz: rpi/create_tftp_static.sh build/rpi-sd-files.tar.gz
	@./rpi/create_tftp_static.sh

# rpi build process involves the following docker image creation
.date_files/rpi_boot_builder_image: rpi/create_rpi_boot_builder_image.sh rpi/Dockerfile rpi/builder_files
	@mkdir -p .date_files
	@./rpi/create_rpi_boot_builder_image.sh && touch $@

# build/pc-usb.dd.gz is the compressed USB image to boot PC nodes
build/pc-usb.dd.gz: .date_files/pc_boot_builder_image
	@mkdir -p build
	@docker run --rm --privileged -v /dev:/dev --entrypoint /root/entry_point.sh waltplatform/pc-boot-builder | \
				gzip > build/pc-usb.dd.gz

# pc build process involves the following docker image creation
.date_files/pc_boot_builder_image: pc/Dockerfile pc/entry_point.sh pc/boot.ipxe
	@mkdir -p .date_files
	@cd ./pc && nice docker build -t waltplatform/pc-boot-builder . && cd .. && touch $@

# build/walt-x86-undionly.kpxe is the compressed ipxe image to serve through TFTP to standard PXE nodes
# it should be copied to repository walt-python-packages at path:
# server/walt/server/threads/main/network/walt-x86-undionly.kpxe
build/walt-x86-undionly.kpxe: .date_files/x86_pxe_boot_builder_image
	@mkdir -p build
	@docker run --rm --entrypoint /root/entry_point.sh waltplatform/x86-pxe-boot-builder \
				> build/walt-x86-undionly.kpxe

# x86-pxe build process involves the following docker image creation
.date_files/x86_pxe_boot_builder_image: x86-pxe/Dockerfile x86-pxe/entry_point.sh x86-pxe/boot.ipxe
	@mkdir -p .date_files
	@cd ./x86-pxe && nice docker build -t waltplatform/x86-pxe-boot-builder . && cd .. && touch $@

