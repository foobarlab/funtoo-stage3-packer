#!/bin/bash -uex

cd /
mkdir -p /mnt/funtoo
mount /dev/sda4 /mnt/funtoo
mkdir /mnt/funtoo/boot
mount /dev/sda1 /mnt/funtoo/boot
