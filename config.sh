#!/bin/bash

export BUILD_BOX_NAME="funtoo-stage3"
export BUILD_BOX_VERSION="0"

export BUILD_GUEST_TYPE="Gentoo_64"
export BUILD_GUEST_DISKSIZE="40000"

# memory/cpus used during box creation:
export BUILD_GUEST_CPUS="4"
export BUILD_GUEST_MEMORY="4096"

# memory/cpus used for final box:
export BUILD_BOX_CPUS="2"
export BUILD_BOX_MEMORY="2048"

export BUILD_BOX_PROVIDER="virtualbox"
export BUILD_BOX_USERNAME="foobarlab"

export BUILD_STAGE3_FILE="stage3-latest.tar.xz"

export BUILD_TIMESTAMP="$(date --iso-8601=seconds)"

BUILD_BOX_DESCRIPTION="$BUILD_BOX_NAME"

export BUILD_FUNTOO_ARCHITECTURE="x86-64bit/generic_64"
export BUILD_FUNTOO_DOWNLOADPATH="https://build.funtoo.org/1.4-release-std/$BUILD_FUNTOO_ARCHITECTURE"

export BUILD_OUTPUT_FILE="$BUILD_BOX_NAME.box"
export BUILD_OUTPUT_FILE_TEMP="$BUILD_BOX_NAME.tmp.box"

export BUILD_SYSTEMRESCUECD_VERSION="5.3.2"
export BUILD_SYSTEMRESCUECD_FILE="systemrescuecd-x86-$BUILD_SYSTEMRESCUECD_VERSION.iso"
export BUILD_SYSTEMRESCUECD_REMOTE_HASH="0a55c61bf24edd04ce44cdf5c3736f739349652154a7e27c4b1caaeb19276ad1"

if [[ -f ./release && -s release ]]; then
	while read line; do
		line_name=`echo $line |cut -d "=" -f1`
		line_value=`echo $line |cut -d "=" -f2 | sed -e 's/"//g'`
		export "BUILD_RELEASE_$line_name=$line_value"
	done < ./release
	export BUILD_BOX_VERSION=`echo $BUILD_RELEASE_VERSION | sed -e 's/\-/./g'`
	export BUILD_OUTPUT_FILE="$BUILD_BOX_NAME-$BUILD_RELEASE_VERSION.box"
	
	BUILD_BOX_DESCRIPTION="Funtoo 1.4 ($BUILD_FUNTOO_ARCHITECTURE)<br><br>$BUILD_BOX_NAME version $BUILD_BOX_VERSION ($BUILD_RELEASE_VERSION_ID)"
	if [ -z ${BUILD_NUMBER+x} ] || [ -z ${BUILD_TAG+x} ]; then
		# without build number/tag
		BUILD_BOX_DESCRIPTION="$BUILD_BOX_DESCRIPTION"
	else
		# for jenkins builds we got some additional information: BUILD_NUMBER, BUILD_ID, BUILD_DISPLAY_NAME, BUILD_TAG, BUILD_URL
		BUILD_BOX_DESCRIPTION="$BUILD_BOX_DESCRIPTION build $BUILD_NUMBER ($BUILD_TAG)"
	fi
fi

export BUILD_BOX_DESCRIPTION="$BUILD_BOX_DESCRIPTION<br>created @$BUILD_TIMESTAMP"

export BUILD_KEEP_MAX_CLOUD_BOXES=4		# set the maximum number of boxes to keep in Vagrant Cloud

if [ $# -eq 0 ]; then
	echo "Executing $0 ..."
	echo "=== Build settings ============================================================="
	env | grep BUILD_ | sort
	echo "================================================================================"
fi
