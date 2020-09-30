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

DATA

mkdir -p /mnt/funtoo/etc/portage/package.use
cat <<'DATA' | tee -a /mnt/funtoo/etc/portage/package.use/stage3-libressl
net-misc/curl http2
net-libs/nghttp2 libressl
DATA

mkdir -p /mnt/funtoo/etc/portage/package.accept_keywords
cat <<'DATA' | tee -a /mnt/funtoo/etc/portage/package.accept_keywords/stage3-libressl
dev-libs/libressl **
DATA
