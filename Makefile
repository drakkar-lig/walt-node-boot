
all: build/rpi-sd.dd.gz build/rpi-sd-files.tar.gz build/pc-usb.dd.gz

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
.date_files/rpi_boot_builder_image: rpi/create_rpi_boot_builder_image.sh rpi/builder_files
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
	@cd ./pc && docker build -t waltplatform/pc-boot-builder . && cd .. && touch $@

