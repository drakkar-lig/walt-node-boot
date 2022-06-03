
all: build/rpi-sd.dd.gz build/rpi-sd-files.tar.gz build/pc-usb.dd.gz build/walt-x86-undionly.kpxe

# build/rpi-sd.dd.gz is the rpi sd card image file
build/rpi-sd.dd.gz: .date_files/rpi_boot_builder_image
	@mkdir -p build
	@docker run --rm --privileged -v /dev:/dev waltplatform/rpi-boot-builder > build/rpi-sd.dd.gz

# to get only the files that should be replaced on the sd card partition
# (useful when debugging), use build/rpi-sd-files.tar.gz
build/rpi-sd-files.tar.gz: .date_files/rpi_boot_builder_image
	@mkdir -p build
	@docker run --rm --privileged -v /dev:/dev waltplatform/rpi-boot-builder --tar > build/rpi-sd-files.tar.gz

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

