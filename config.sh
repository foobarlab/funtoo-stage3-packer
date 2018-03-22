#!/bin/bash

export BUILD_BOX_NAME="funtoo-stage3"
export BUILD_BOX_VERSION="0"
export BUILD_GUEST_TYPE="Gentoo_64"
export BUILD_GUEST_CPUS="4"
export BUILD_GUEST_MEMORY="2048"

export BUILD_STAGE3_FILE="stage3-latest.tar.xz"

# x86-64bit/generic64 build (multilib)
#export BUILD_FUNTOO_DOWNLOADPATH="https://build.funtoo.org/funtoo-current/x86-64bit/generic_64"
#export BUILD_FUNTOO_DOWNLOADPATH="https://ftp.osuosl.org/pub/funtoo/funtoo-current/x86-64bit/generic_64"
#export BUILD_BOX_DESCRIPTION="Funtoo stage3 installation (x86-64bit, generic64)"

# pure64/generic64 build
#export BUILD_FUNTOO_DOWNLOADPATH="https://build.funtoo.org/funtoo-current/pure64/generic_64-pure64"
export BUILD_FUNTOO_DOWNLOADPATH="https://ftp.osuosl.org/pub/funtoo/funtoo-current/pure64/generic_64-pure64"
export BUILD_BOX_DESCRIPTION="Funtoo stage3 installation (pure64, generic64)"

export BUILD_OUTPUT_FILE="$BUILD_BOX_NAME.box"

export BUILD_SYSTEMRESCUECD_FILE="systemrescuecd-x86-5.2.1.iso"
export BUILD_SYSTEMRESCUECD_REMOTE_HASH="d76d9444a73ce2127e489f54b0ce1cb9057ae470459dc3fb32e8c916f7cbfe2e"

# dynamically set actual BUILD_BOX_VERSION and some additional vars from extracted release info 
if [ -f ./release ]; then
	while read line; do
		line_name=`echo $line |cut -d "=" -f1`
		line_value=`echo $line |cut -d "=" -f2`
		export "BUILD_RELEASE_$line_name=$line_value"
	done < ./release
	export BUILD_BOX_VERSION=`echo $BUILD_RELEASE_VERSION | sed -e 's/\-/./g'`
fi

# output info only if there is no argument given
if [ $# -eq 0 ]; then
	echo "Executing $0 ..."
	echo "=== Build settings ============================================================="
	env | grep BUILD_
	echo "================================================================================"
fi
