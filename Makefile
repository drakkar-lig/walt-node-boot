
all: build/rpi/walt.date build/rpi/rpi-sd-files.tar.gz build/rpi/rpi-4-sd-recovery.tar.gz build/rpi/rpi-5-sd-recovery.tar.gz build/rpi/tftp-static.tar.gz build/pc-usb.dd.gz build/walt-x86-undionly.kpxe build/walt-x86-64-snponly.efi

# network boot files and archives for raspberry pi boards
build/rpi/%: .date_files/rpi_boot_builder_image
	@mkdir -p build/rpi
	@docker run --rm waltplatform/rpi-boot-builder $* > build/$*

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

# build/walt-x86-undionly.kpxe and build/walt-x86-64-snponly.efi are the
# ipxe images walt serves through TFTP to standard BIOS & UEFI PXE nodes.
# they should be copied to repository walt-python-packages at path:
# server/walt/server/exports/
build/walt-x86-undionly.kpxe: .date_files/x86_pxe_boot_builder_image
	@mkdir -p build
	@docker run --rm --entrypoint /root/entry_point.sh waltplatform/x86-pxe-boot-builder \
				undionly.kpxe > build/walt-x86-undionly.kpxe
build/walt-x86-64-snponly.efi: .date_files/x86_pxe_boot_builder_image
	@mkdir -p build
	@docker run --rm --entrypoint /root/entry_point.sh waltplatform/x86-pxe-boot-builder \
				snponly.efi > build/walt-x86-64-snponly.efi

# x86-pxe build process involves the following docker image creation
.date_files/x86_pxe_boot_builder_image: x86-pxe/Dockerfile x86-pxe/entry_point.sh x86-pxe/boot.ipxe
	@mkdir -p .date_files
	@cd ./x86-pxe && nice docker build -t waltplatform/x86-pxe-boot-builder . && cd .. && touch $@

