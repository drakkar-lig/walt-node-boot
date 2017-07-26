FROM debian:stretch

### Making the process completely noninteractive
ENV DEBIAN_FRONTEND noninteractive
### Defining English as default language
ENV LANG C

### Installing essential apps
RUN apt-get update && apt-get install -y vim grub-pc ipxe

### Adding the entrypoint script to the image
ADD entry_point.sh /root/

WORKDIR /root/

