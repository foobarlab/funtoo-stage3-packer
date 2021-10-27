#!/bin/bash -uex
# vim: ts=2 sw=2 et

if [ -z ${BUILD_RUN:-} ]; then
  echo "This script can not be run directly! Aborting."
  exit 1
fi

cd /mnt/funtoo
if [ -f "$BUILD_STAGE3_PATH" ]
then
  mv $BUILD_STAGE3_PATH /mnt/funtoo
else
  echo "File '$BUILD_STAGE3_PATH' does not exist. Aborting."
  exit 1
fi

cd /mnt/funtoo
tar --numeric-owner --xattrs --xattrs-include='*' -xpf $BUILD_STAGE3_FILE
rm -f $BUILD_STAGE3_FILE
ls -l
