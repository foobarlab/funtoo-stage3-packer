#!/bin/bash -uex
# vim: ts=2 sw=2 et

if [ -z ${BUILD_RUN:-} ]; then
  echo "This script can not be run directly! Aborting."
  exit 1
fi

cd /
mkdir -p /mnt/funtoo
mount /dev/sda4 /mnt/funtoo
mkdir /mnt/funtoo/boot
mount /dev/sda1 /mnt/funtoo/boot
