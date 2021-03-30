#!/bin/bash -uex

if [ -z ${BUILD_RUN:-} ]; then
  echo "This script can not be run directly! Aborting."
  exit 1
fi

cat <<'DATA' | tee -a /mnt/funtoo/etc/portage/make.conf
# Contains local system settings for Portage system
# Please consult /usr/share/portage/config/make.conf.example for a more
# detailed example.

USE="bindist"

ACCEPT_LICENSE="-* @FREE @BINARY-REDISTRIBUTABLE"

CURL_SSL="libressl"

MAKEOPTS="BUILD_MAKEOPTS"

DATA
sed -i 's/BUILD_MAKEOPTS/'"${BUILD_MAKEOPTS}"'/g' /mnt/funtoo/etc/portage/make.conf

mkdir -p /mnt/funtoo/etc/portage/package.use
cat <<'DATA' | tee -a /mnt/funtoo/etc/portage/package.use/stage3
net-misc/curl http2
net-libs/nghttp2 libressl
DATA

mkdir -p /mnt/funtoo/etc/portage/package.accept_keywords
cat <<'DATA' | tee -a /mnt/funtoo/etc/portage/package.accept_keywords/stage3-libressl
dev-libs/libressl **
DATA
cat <<'DATA' | tee -a /mnt/funtoo/etc/portage/package.accept_keywords/stage3-grub
=sys-boot/grub-2.04-r1 **
DATA
