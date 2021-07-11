#!/bin/sh

# Fix image to use SmartOS cloud-init data provder.
sudo mount-image-callback focal-server-cloudimg-amd64.dist.img -- sh -c 'sed -i "s/, None/, SmartOS, None/" $MOUNTPOINT/etc/cloud/cloud.cfg.d/90_dpkg.cfg; apt-get -y install joyent-mdata-client'

# Create a ZFS volume to write the image to
sudo fallocate -l 8G /myzpool.file
sudo zpool create myzpool /myzpool.file
sudo zfs create -V 5G myzpool/ubuntu

# Write the image and store it as a gzipped ZFS volume
sudo dd if=focal-server-cloudimg-amd64.dist.img of=/dev/zvol/myzpool/ubuntu bs=1M
sudo zfs snapshot myzpool/ubuntu@snap
sudo zfs send myzpool/ubuntu@snap | gzip > focal-server-cloudimg-amd64.dist.img.zvol.gz

# Create json file
sudo cp json-template/image.json focal-server-cloudimg-amd64.json
UUID=$(uuidgen)
SHA1=$(shasum focal-server-cloudimg-amd64.dist.img.zvol.gz |awk '{print $1}')
SIZE=$(ls -l focal-server-cloudimg-amd64.dist.img.zvol.gz |awk '{print $5}')
DATE=$(date -u +"%Y-%m-%d")
DATETIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
sed -i \
    -e "s#<image-uuid>#${UUID}#" \
    -e "s#<sha1>#${SHA1}#" \
    -e "s#<image-size>#${SIZE}#" \
    -e "s#<date>#${DATE}#g" \
    -e "s#<datetime>#${DATETIME}#" \
    focal-server-cloudimg-amd64.json

# Cleanup
sudo rm joyent-mdata-client_*.deb
sudo rm cloud-init_*.deb
sudo zfs destroy -r myzpool/ubuntu
sudo zpool destroy myzpool
sudo rm /myzpool.file
