#!/bin/bash
set -e

target="$1"
if [ ! -e "/opt/$target" ]
then
	echo "Unexpected argument: ${target}" >&2
    exit 1
fi
cat /opt/$target
