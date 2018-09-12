#!/bin/bash

export BUILD_BOX_NAME="funtoo-stage3"
export BUILD_BOX_VERSION="0"

export BUILD_GUEST_TYPE="Gentoo_64"
export BUILD_GUEST_CPUS="4"
export BUILD_GUEST_MEMORY="2048"
export BUILD_GUEST_DISKSIZE="100000"

export BUILD_BOX_PROVIDER="virtualbox"
export BUILD_BOX_USERNAME="foobarlab"

export BUILD_STAGE3_FILE="stage3-latest.tar.xz"
export BUILD_STAGE3_FILE_HASH="$BUILD_STAGE3_FILE.hash.txt"

export BUILD_TIMESTAMP="$(date --iso-8601=seconds)"

BUILD_BOX_DESCRIPTION="$BUILD_BOX_NAME"

# x86-64bit/generic64 build (multilib)
#export BUILD_FUNTOO_DOWNLOADPATH="https://build.funtoo.org/funtoo-current/x86-64bit/generic_64"
#export BUILD_FUNTOO_DOWNLOADPATH="https://ftp.osuosl.org/pub/funtoo/funtoo-current/x86-64bit/generic_64"

# pure64/generic64 build
export BUILD_FUNTOO_DOWNLOADPATH="https://build.funtoo.org/funtoo-current/pure64/generic_64-pure64"
#export BUILD_FUNTOO_DOWNLOADPATH="https://ftp.osuosl.org/pub/funtoo/funtoo-current/pure64/generic_64-pure64"

export BUILD_OUTPUT_FILE="$BUILD_BOX_NAME.box"
export BUILD_OUTPUT_FILE_TEMP="$BUILD_BOX_NAME.tmp.box"

# FIXME: extract latest version and its sha256sum from the webpage
export BUILD_SYSTEMRESCUECD_VERSION="5.3.0"
export BUILD_SYSTEMRESCUECD_FILE="systemrescuecd-x86-$BUILD_SYSTEMRESCUECD_VERSION.iso"
export BUILD_SYSTEMRESCUECD_REMOTE_HASH="1eb6edc88c744d60fce810d14cd82724c86ba5d1c3cd9270259f39f82ef589f3"

if [[ -f ./release && -s release ]]; then
	while read line; do
		line_name=`echo $line |cut -d "=" -f1`
		line_value=`echo $line |cut -d "=" -f2 | sed -e 's/"//g'`
		export "BUILD_RELEASE_$line_name=$line_value"
	done < ./release
	export BUILD_BOX_VERSION=`echo $BUILD_RELEASE_VERSION | sed -e 's/\-/./g'`
	export BUILD_OUTPUT_FILE="$BUILD_BOX_NAME-$BUILD_RELEASE_VERSION.box"
	
	BUILD_BOX_DESCRIPTION="$BUILD_BOX_NAME version $BUILD_BOX_VERSION ($BUILD_RELEASE_VERSION_ID)"
	if [ -z ${BUILD_NUMBER+x} ] || [ -z ${BUILD_TAG+x} ]; then
		# without build number 
		BUILD_BOX_DESCRIPTION="$BUILD_BOX_DESCRIPTION custom build"
	else
		# for jenkins builds we got some additional information: BUILD_NUMBER, BUILD_ID, BUILD_DISPLAY_NAME, BUILD_TAG, BUILD_URL
		BUILD_BOX_DESCRIPTION="$BUILD_BOX_DESCRIPTION build $BUILD_NUMBER ($BUILD_TAG)"
	fi
	
fi

export BUILD_BOX_DESCRIPTION="$BUILD_BOX_DESCRIPTION<br>created @$BUILD_TIMESTAMP"

export BUILD_KEEP_MAX_CLOUD_BOXES=2		# set the maximum number of boxes to keep in Vagrant Cloud

if [ $# -eq 0 ]; then
	echo "Executing $0 ..."
	echo "=== Build settings ============================================================="
	env | grep BUILD_ | sort
	echo "================================================================================"
fi
