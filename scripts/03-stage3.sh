#!/bin/bash -uex

cd /mnt/funtoo
if [ -f "$BUILD_STAGE3_PATH" ]
then
	mv $BUILD_STAGE3_PATH /mnt/funtoo
else
	echo "File '$BUILD_STAGE3_PATH' does not exist. Aborting"
	exit 1

#	wget $BUILD_STAGE3_URL
#	if [ $? -ne 0 ]; then
#    	echo "Could not download '$BUILD_STAGE3_URL'. Exit code from wget was $?."
#    	exit 1
#    fi
#	mv $BUILD_STAGE3_FILE /mnt/funtoo

fi

cd /mnt/funtoo
tar xpf $BUILD_STAGE3_FILE
rm -f $BUILD_STAGE3_FILE
ls -l