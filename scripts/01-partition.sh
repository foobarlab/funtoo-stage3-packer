#!/bin/bash -uex

if [ -z ${BUILD_RUN:-} ]; then
  echo "This script can not be run directly! Aborting."
  exit 1
fi

sgdisk \
  -n 1:0:+480M -t 1:8300 -c 1:"boot" \
  -n 2:0:+32M  -t 2:ef02 -c 2:"BIOS boot partition" \
  -n 3:0:+2G   -t 3:8200 -c 3:"swap" \
  -n 4:0:0     -t 4:8300 -c 4:"rootfs" \
  -p /dev/sda

sync

mkfs.ext2 /dev/sda1
mkfs.ext4 /dev/sda4

mkswap /dev/sda3 && swapon /dev/sda3
