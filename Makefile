
DOCKER_RPI_BOOT_BUILDER_IMAGE="waltplatform/rpi-boot-builder"

all: build/rpi-sd.dd.gz build/rpi-sd-files.tar.gz

# build/rpi-sd.dd.gz is the rpi sd card image file
build/rpi-sd.dd.gz: .date_files/rpi_boot_builder_image
	@mkdir -p build
	@docker run --privileged -v /dev:/dev "$(DOCKER_RPI_BOOT_BUILDER_IMAGE)" > build/rpi-sd.dd.gz

# to get only the files that should be replaced on the sd card partition
# (useful when debugging), use build/rpi-sd-files.tar.gz
build/rpi-sd-files.tar.gz: .date_files/rpi_boot_builder_image
	@mkdir -p build
	@docker run --privileged -v /dev:/dev "$(DOCKER_RPI_BOOT_BUILDER_IMAGE)" --tar > build/rpi-sd-files.tar.gz

# the build process involves the following docker image creation
.date_files/rpi_boot_builder_image: create_rpi_boot_builder_image.sh builder_files
	@mkdir -p .date_files
	@./create_rpi_boot_builder_image.sh && touch $@


