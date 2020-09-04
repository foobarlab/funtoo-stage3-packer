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

DATA
