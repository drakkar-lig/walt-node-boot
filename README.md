walt-node-boot
==============

Home of walt node early booting phase.

This repository provides the code for the early booting phase of WalT nodes,
from the hardware initialization up to the hand-off to the selected WalT image.

As of now (sept 2016), the following types of WalT nodes are available:
* raspberry pi B/B+
* raspberry pi 2 model B
* raspberry pi 3 model B
* x86-64 pc nodes 	 (booting the USB image generated here)

(The SD card built for raspberry pi is compatible with all listed models)

Typing `make` in this repository allows to build docker images.
These images are kinds of "containers" for the material needed to
connect a given node type to a WalT system. See below.

Usage
=====

Build the image(s):
```
$ make
```

