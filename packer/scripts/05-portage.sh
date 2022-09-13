#!/bin/bash -uex
# vim: ts=2 sw=2 et

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

#CURL_SSL="nss"
#CURL_SSL="libressl"
CURL_SSL="gnutls"

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

mkdir -p /mnt/funtoo/etc/portage/package.license
cat <<'DATA' | tee -a /mnt/funtoo/etc/portage/package.license/stage3-curl
net-misc/curl curl
DATA
