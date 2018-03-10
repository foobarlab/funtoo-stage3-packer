#!/bin/bash -uex

if [ -z ${BUILD_RUN:-} ]; then
  echo "This script can not be run directly! Aborting."
  exit 1
fi

cd /mnt/funtoo
if [ -f "$BUILD_STAGE3_PATH" ]
then
	mv $BUILD_STAGE3_PATH /mnt/funtoo
else
	echo "File '$BUILD_STAGE3_PATH' does not exist. Aborting"
	exit 1
fi

cd /mnt/funtoo
tar xpf $BUILD_STAGE3_FILE
rm -f $BUILD_STAGE3_FILE
ls -l
