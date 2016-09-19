
DOCKER_RPI_BOOT_IMAGE=$(shell docker run waltplatform/dev-master \
							conf-get DOCKER_RPI_BOOT_IMAGE)
DOCKER_RPI_BOOT_BUILDER_IMAGE=$(shell docker run waltplatform/dev-master \
							conf-get DOCKER_RPI_BOOT_BUILDER_IMAGE)

all: .date_files/rpi_boot_image

.date_files/rpi_boot_image: create_rpi_boot_image.sh .date_files/rpi_boot_builder_image
	./create_rpi_boot_image.sh && touch $@

.date_files/rpi_boot_builder_image: create_rpi_boot_builder_image.sh builder_files
	./create_rpi_boot_builder_image.sh && touch $@

publish:
	docker push $(DOCKER_RPI_BOOT_IMAGE)

# to get the files that should be replaced on the sd card partition
# (useful when debugging)
# $ make rpi-tar-dump > rpi-sd-files.tar.gz
rpi-tar-dump:
	@docker run --privileged -v /dev:/dev $(DOCKER_RPI_BOOT_BUILDER_IMAGE) --tar

# to get the sd card image file
# $ make rpi-sd-dump > rpi-sd.dd.gz
rpi-sd-dump:
	@docker run $(DOCKER_RPI_BOOT_IMAGE)

