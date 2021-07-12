#!/bin/bash

# imports
. ./lib/functions.sh
require_commands git nproc

set -a

# ----------------------------!  edit settings below  !----------------------------

export BUILD_BOX_NAME="funtoo-stage3"
export BUILD_BOX_FUNTOO_VERSION="1.4"
export BUILD_BOX_SOURCES="https://github.com/foobarlab/funtoo-stage3-packer"

export BUILD_GUEST_TYPE="Gentoo_64"
export BUILD_GUEST_DISKSIZE="50000"    # dynamic disksize in MB, e.g. 50000 => 50 GB

export BUILD_TIMEZONE="UTC"

# memory/cpus used for final box:
export BUILD_BOX_CPUS="2"
export BUILD_BOX_MEMORY="2048"

export BUILD_BOX_PROVIDER="virtualbox"
export BUILD_BOX_USERNAME="foobarlab"

export BUILD_REBUILD_SYSTEM=false          # set to 'true': rebuild @system (e.g. required for toolchain rebuild)

export BUILD_GUEST_ADDITIONS=true          # set to 'true': install virtualbox guest additions
export BUILD_KEEP_MAX_CLOUD_BOXES=1        # set the maximum number of boxes to keep in Vagrant Cloud

export BUILD_RELEASE_VERSION_ID="2021-07-01"	# FIXME release file sometimes missing information (workaround: copy manually from https://www.funtoo.org/Intel64-nehalem, todo: determine from stage3 file date if not present in /etc/os-release)

# enable custom overlay?
export BUILD_CUSTOM_OVERLAY=true
export BUILD_CUSTOM_OVERLAY_NAME="foobarlab-stage3"
export BUILD_CUSTOM_OVERLAY_BRANCH="stage3"
export BUILD_CUSTOM_OVERLAY_URL="https://github.com/foobarlab/foobarlab-overlay.git"

# ----------------------------!  do not edit below this line  !----------------------------

export BUILD_STAGE3_FILE="stage3-latest.tar.xz"
export BUILD_FUNTOO_ARCHITECTURE="x86-64bit/intel64-nehalem"
export BUILD_FUNTOO_DOWNLOADPATH="https://build.funtoo.org/1.4-release-std/$BUILD_FUNTOO_ARCHITECTURE"

export BUILD_OUTPUT_FILE="$BUILD_BOX_NAME.box"
export BUILD_OUTPUT_FILE_TEMP="$BUILD_BOX_NAME.tmp.box"

export BUILD_SYSRESCUECD_VERSION="5.3.2"
export BUILD_SYSRESCUECD_FILE="systemrescuecd-x86-$BUILD_SYSRESCUECD_VERSION.iso"
export BUILD_SYSRESCUECD_REMOTE_HASH="0a55c61bf24edd04ce44cdf5c3736f739349652154a7e27c4b1caaeb19276ad1"

export BUILD_TIMESTAMP="$(date --iso-8601=seconds)"

# detect number of system cpus available (select half of cpus for best performance)
export BUILD_CPUS=$((`nproc --all` / 2))
let "jobs = $BUILD_CPUS + 1"       # calculate number of jobs (threads + 1)
export BUILD_MAKEOPTS="-j${jobs}"

# determine ram available (select min and max)
BUILD_MEMORY_MIN=4096 # we want at least 4G ram for our build
# calculate max memory (set to 1/2 of available memory)
BUILD_MEMORY_MAX=$(((`grep MemTotal /proc/meminfo | awk '{print $2}'` / 1024 / 1024 / 2 + 1 ) * 1024))
let "memory = $BUILD_CPUS * 1024"   # calculate 1G ram for each cpu
BUILD_MEMORY="${memory}"
BUILD_MEMORY=$(($BUILD_MEMORY < $BUILD_MEMORY_MIN ? $BUILD_MEMORY_MIN : $BUILD_MEMORY)) # lower limit (min)
BUILD_MEMORY=$(($BUILD_MEMORY > $BUILD_MEMORY_MAX ? $BUILD_MEMORY_MAX : $BUILD_MEMORY)) # upper limit (max)
export BUILD_MEMORY

export BUILD_BOX_VERSION=`echo $BUILD_BOX_FUNTOO_VERSION | sed -e 's/\.//g'`

BUILD_BOX_DESCRIPTION="$BUILD_BOX_NAME"

if [[ -f ./release && -s release ]]; then
	while read line; do
		line_name=`echo $line |cut -d "=" -f1`
		line_value=`echo $line |cut -d "=" -f2 | sed -e 's/"//g'`
		export "BUILD_RELEASE_$line_name=$line_value"
	done < ./release
    BUILD_BOX_RELEASE_VERSION=`echo $BUILD_RELEASE_VERSION_ID | sed -e 's/\-//g'`
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
	if [ $# -eq 0 ]; then
		echo "build version => $BUILD_BOX_VERSION"
	fi
	echo $BUILD_BOX_VERSION > build_version
	export BUILD_OUTPUT_FILE="$BUILD_BOX_NAME-$BUILD_BOX_VERSION.box"

	BUILD_BOX_DESCRIPTION="Funtoo $BUILD_BOX_FUNTOO_VERSION ($BUILD_FUNTOO_ARCHITECTURE)<br><br>$BUILD_BOX_NAME version $BUILD_BOX_VERSION ($BUILD_RELEASE_VERSION_ID)"
	if [ -z ${BUILD_NUMBER+x} ] || [ -z ${BUILD_TAG+x} ]; then
		# without build number/tag
		BUILD_BOX_DESCRIPTION="$BUILD_BOX_DESCRIPTION"
	else
		# for jenkins builds we got some additional information: BUILD_NUMBER, BUILD_ID, BUILD_DISPLAY_NAME, BUILD_TAG, BUILD_URL
		BUILD_BOX_DESCRIPTION="$BUILD_BOX_DESCRIPTION build $BUILD_NUMBER ($BUILD_TAG)"
	fi
fi

if [[ -f ./build_time && -s build_time ]]; then
	export BUILD_RUNTIME=`cat build_time`
	export BUILD_RUNTIME_FANCY="Total build runtime was $BUILD_RUNTIME."
else
	export BUILD_RUNTIME="unknown"
	export BUILD_RUNTIME_FANCY="Total build runtime was not logged."
fi

BUILD_BOX_DESCRIPTION="$BUILD_BOX_DESCRIPTION<br>created @$BUILD_TIMESTAMP<br>"

# check if in git environment and collect git data (if any)
export BUILD_GIT=$(echo `git rev-parse --is-inside-work-tree 2>/dev/null || echo "false"`)
if [ $BUILD_GIT == "true" ]; then
  export BUILD_GIT_COMMIT_REPO=`git config --get remote.origin.url`
  export BUILD_GIT_COMMIT_BRANCH=`git rev-parse --abbrev-ref HEAD`
  export BUILD_GIT_COMMIT_ID=`git rev-parse HEAD`
  export BUILD_GIT_COMMIT_ID_SHORT=`git rev-parse --short HEAD`
  export BUILD_GIT_COMMIT_ID_HREF="${BUILD_BOX_SOURCES}/tree/${BUILD_GIT_COMMIT_ID}"
  export BUILD_GIT_LOCAL_MODIFICATIONS=$(if [ "`git diff --shortstat`" == "" ]; then echo 'false'; else echo 'true'; fi)
  BUILD_BOX_DESCRIPTION="$BUILD_BOX_DESCRIPTION<br>Git repository: $BUILD_GIT_COMMIT_REPO"
  if [ $BUILD_GIT_LOCAL_MODIFICATIONS == "true" ]; then
    export BUILD_BOX_DESCRIPTION="$BUILD_BOX_DESCRIPTION<br>This build is in an experimental work-in-progress state. Local modifications have not been committed to Git repository yet.<br>$BUILD_RUNTIME_FANCY"
  else
    export BUILD_BOX_DESCRIPTION="$BUILD_BOX_DESCRIPTION<br>This build is based on branch $BUILD_GIT_COMMIT_BRANCH (commit id <a href=\\\"$BUILD_GIT_COMMIT_ID_HREF\\\">$BUILD_GIT_COMMIT_ID_SHORT</a>).<br>$BUILD_RUNTIME_FANCY"
  fi
else
  BUILD_BOX_DESCRIPTION="$BUILD_BOX_DESCRIPTION<br>Origin source code: $BUILD_BOX_SOURCES"
  export BUILD_BOX_DESCRIPTION="$BUILD_BOX_DESCRIPTION<br>This build is not version controlled yet.<br>$BUILD_RUNTIME_FANCY"
fi

if [ $# -eq 0 ]; then
	echo "Executing $0 ..."
	echo "=========================================================================="
	echo "===========================[  Build settings  ]==========================="
	echo "=========================================================================="
	env | grep BUILD_ | sort | awk -F"=" '{ printf("\033[1;37m%.40s \033[0;37m%s\n",  $1 "\033[2;37m........................................\033[0;37m" , $2) }'
	echo "=========================================================================="
fi
