#!/bin/sh

if [ ! -f focal-server-cloudimg-amd64.img ]; then
	wget 'https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img'
fi

qemu-img convert -O raw focal-server-cloudimg-amd64.img focal-server-cloudimg-amd64.dist.img
