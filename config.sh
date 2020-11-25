#!/bin/bash

command -v git >/dev/null 2>&1 || { echo "Command 'git' required but it's not installed.  Aborting." >&2; exit 1; }

export BUILD_RELEASE_VERSION_ID="-2020-11-16" # FIXME VERSION_ID has been stripped from /etc/os-release, hardcoding here

export BUILD_BOX_NAME="funtoo-stage3"
export BUILD_BOX_FUNTOO_VERSION="1.4"
export BUILD_BOX_SOURCES="https://github.com/foobarlab/funtoo-stage3-packer"

export BUILD_GUEST_TYPE="Gentoo_64"
export BUILD_GUEST_DISKSIZE="50000"    # dynamic disksize in MB, e.g. 50000 => 50 GB

# number of cores used during box creation (memory is calculated automatically):
export BUILD_CPUS="4"

# memory/cpus used for final box:
export BUILD_BOX_CPUS="2"
export BUILD_BOX_MEMORY="2048"

export BUILD_BOX_PROVIDER="virtualbox"
export BUILD_BOX_USERNAME="foobarlab"

export BUILD_GUEST_ADDITIONS=true          # set to 'true': install virtualbox guest additions
export BUILD_KEEP_MAX_CLOUD_BOXES=1        # set the maximum number of boxes to keep in Vagrant Cloud

# ----------------------------! do not edit below this line !----------------------------

export BUILD_STAGE3_FILE="stage3-latest.tar.xz"
export BUILD_FUNTOO_ARCHITECTURE="x86-64bit/generic_64"
export BUILD_FUNTOO_DOWNLOADPATH="https://build.funtoo.org/1.4-release-std/$BUILD_FUNTOO_ARCHITECTURE"

export BUILD_OUTPUT_FILE="$BUILD_BOX_NAME.box"
export BUILD_OUTPUT_FILE_TEMP="$BUILD_BOX_NAME.tmp.box"

export BUILD_SYSTEMRESCUECD_VERSION="5.3.2"
export BUILD_SYSTEMRESCUECD_FILE="systemrescuecd-x86-$BUILD_SYSTEMRESCUECD_VERSION.iso"
export BUILD_SYSTEMRESCUECD_REMOTE_HASH="0a55c61bf24edd04ce44cdf5c3736f739349652154a7e27c4b1caaeb19276ad1"

export BUILD_TIMESTAMP="$(date --iso-8601=seconds)"

let "jobs = $BUILD_CPUS + 1"       # calculate number of jobs (threads + 1)
export BUILD_MAKEOPTS="-j${jobs}"
let "memory = $jobs * 2048"        # recommended 2GB for each job
export BUILD_MEMORY="${memory}"

export BUILD_BOX_VERSION=`echo $BUILD_BOX_FUNTOO_VERSION | sed -e 's/\.//g'`

BUILD_BOX_DESCRIPTION="$BUILD_BOX_NAME"

if [[ -f ./release && -s release ]]; then
	while read line; do
		line_name=`echo $line |cut -d "=" -f1`
		line_value=`echo $line |cut -d "=" -f2 | sed -e 's/"//g'`
		export "BUILD_RELEASE_$line_name=$line_value"
	done < ./release
    export BUILD_RELEASE_VERSION_ID_SHORT=`echo ${BUILD_RELEASE_VERSION_ID:1}`
	BUILD_BOX_RELEASE_VERSION=`echo $BUILD_RELEASE_VERSION_ID_SHORT | sed -e 's/\-//g'`
	BUILD_BOX_RELEASE_VERSION=`echo $BUILD_BOX_RELEASE_VERSION | sed -e 's/20//'`
    export BUILD_BOX_RELEASE_VERSION
	BUILD_BOX_VERSION=$BUILD_BOX_VERSION.$BUILD_BOX_RELEASE_VERSION

	if [ -f build_version ]; then
		BUILD_BOX_VERSION=$(<build_version)
	else
		# generate build_number
		if [ -z ${BUILD_NUMBER:-} ] ; then
			if [ -f build_number ]; then
				# read from file and increase by one
				BUILD_NUMBER=$(<build_number)
				BUILD_NUMBER=$((BUILD_NUMBER+1))
			else
				BUILD_NUMBER=0
			fi
			export BUILD_NUMBER
			# store for later reuse in file 'build_number'
			echo $BUILD_NUMBER > build_number
			BUILD_BOX_VERSION=$BUILD_BOX_VERSION.$BUILD_NUMBER
		fi
	fi
	export BUILD_BOX_VERSION
	echo "build version => $BUILD_BOX_VERSION"
	echo $BUILD_BOX_VERSION > build_version
	export BUILD_OUTPUT_FILE="$BUILD_BOX_NAME-$BUILD_BOX_VERSION.box"

	BUILD_BOX_DESCRIPTION="Funtoo $BUILD_BOX_FUNTOO_VERSION ($BUILD_FUNTOO_ARCHITECTURE)<br><br>$BUILD_BOX_NAME version $BUILD_BOX_VERSION ($BUILD_RELEASE_VERSION_ID_SHORT)"
	if [ -z ${BUILD_NUMBER+x} ] || [ -z ${BUILD_TAG+x} ]; then
		# without build number/tag
		BUILD_BOX_DESCRIPTION="$BUILD_BOX_DESCRIPTION"
	else
		# for jenkins builds we got some additional information: BUILD_NUMBER, BUILD_ID, BUILD_DISPLAY_NAME, BUILD_TAG, BUILD_URL
		BUILD_BOX_DESCRIPTION="$BUILD_BOX_DESCRIPTION build $BUILD_NUMBER ($BUILD_TAG)"
	fi
fi

export BUILD_GIT_COMMIT_ID=`git rev-parse HEAD`
export BUILD_GIT_COMMIT_ID_SHORT=`git rev-parse --short HEAD`
export BUILD_GIT_COMMIT_ID_HREF="${BUILD_BOX_SOURCES}/tree/${BUILD_GIT_COMMIT_ID}"

export BUILD_BOX_DESCRIPTION="$BUILD_BOX_DESCRIPTION<br>created @$BUILD_TIMESTAMP<br><br>Source code: $BUILD_BOX_SOURCES<br>This build is based on commit id <a href=\\\"$BUILD_GIT_COMMIT_ID_HREF\\\">$BUILD_GIT_COMMIT_ID_SHORT</a>"

if [ $# -eq 0 ]; then
	echo "Executing $0 ..."
	echo "=== Build settings ============================================================="
	env | grep BUILD_ | sort
	echo "================================================================================"
fi
