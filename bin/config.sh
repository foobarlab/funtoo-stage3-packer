#!/bin/bash -ue
# vim: ts=4 sw=4 et

[[ -v BUILD_ROOT ]] || BUILD_ROOT="${PWD}"   # FIXME try to set correct path (e.g. when run from inside bin dir)
source "${BUILD_LIB_UTILS:-./bin/lib/utils.sh}" "$*"
require_commands git nproc
set -a

# ----------------------------!  default settings below  !----------------------------

BUILD_BOX_PROVIDER="virtualbox"
BUILD_GUEST_TYPE="Gentoo_64"

BUILD_BOX_USERNAME="foobarlab"
BUILD_BOX_NAME="funtoo-stage3"
BUILD_BOX_SOURCES="https://github.com/foobarlab/funtoo-stage3-packer"

# memory/cpus used for final box:
BUILD_BOX_CPUS="2"
BUILD_BOX_MEMORY="2048"
BUILD_GUEST_DISKSIZE="20480"    # dynamic disksize in MB, e.g. 20480 => 20 GB

BUILD_TIMEZONE="UTC"

BUILD_REBUILD_SYSTEM=false          # set to 'true' to rebuild @system (e.g. required for toolchain rebuild)

BUILD_KEEP_MAX_CLOUD_BOXES=1        # set the maximum number of boxes to keep in Vagrant Cloud

# Funtoo 1.4 (current more or less stable)
BUILD_BOX_FUNTOO_VERSION="1.4"
BUILD_RELEASE="${BUILD_BOX_FUNTOO_VERSION}-release-std"
BUILD_RELEASE_VERSION_ID="2023-02-01"
BUILD_FUNTOO_ARCHITECTURE="x86-64bit/intel64-nehalem"
BUILD_FUNTOO_STAGE3="stage3-intel64-nehalem-${BUILD_BOX_FUNTOO_VERSION}-release-std"
BUILD_GUEST_ADDITIONS=true          # set to 'true' to install virtualbox guest additions

# Funtoo next (experimental next-release, see: https://forums.funtoo.org/topic/4970-announcing-next-release/)
#BUILD_BOX_FUNTOO_VERSION="0"
#BUILD_RELEASE="next"
#BUILD_RELEASE_VERSION_ID="2021-12-25"               # FIXME parse xml from https://build.funtoo.org/index.xml to get version
#BUILD_FUNTOO_ARCHITECTURE="x86-64bit/generic_64"    # FIXME arch/cpu into separate vars
#BUILD_FUNTOO_STAGE3="stage3-generic_64-next"        # FIXME build string from cpu + release
#BUILD_GUEST_ADDITIONS=false                         # set to 'true' to install virtualbox guest additions

# enable custom overlay?
BUILD_CUSTOM_OVERLAY=true
BUILD_CUSTOM_OVERLAY_NAME="foobarlab-stage3"
BUILD_CUSTOM_OVERLAY_BRANCH="stage3"
BUILD_CUSTOM_OVERLAY_URL="https://github.com/foobarlab/foobarlab-overlay.git"

# ----------------------------!  do not edit below this line  !----------------------------

# override build settings above? load build.conf ...
[[ -f ""${BUILD_FILE_BUILDCONF}"" ]] && source "${BUILD_FILE_BUILDCONF}"

BUILD_STAGE3_FILE="${BUILD_DIR_DOWNLOAD}/stage3-latest.tar.xz"
BUILD_FUNTOO_DOWNLOADPATH="https://build.funtoo.org/$BUILD_RELEASE/$BUILD_FUNTOO_ARCHITECTURE"

BUILD_OUTPUT_FILE="${BUILD_DIR_BUILD}/${BUILD_BOX_NAME}.box"
BUILD_OUTPUT_FILE_TEMP="${BUILD_DIR_BUILD}/${BUILD_BOX_NAME}.tmp.box"

BUILD_SYSRESCUECD_VERSION="5.3.2"
BUILD_SYSRESCUECD_FILENAME="systemrescuecd-x86-$BUILD_SYSRESCUECD_VERSION.iso"
BUILD_SYSRESCUECD_FILE="${BUILD_DIR_DOWNLOAD}/${BUILD_SYSRESCUECD_FILENAME}"
BUILD_SYSRESCUECD_REMOTE_HASH="0a55c61bf24edd04ce44cdf5c3736f739349652154a7e27c4b1caaeb19276ad1"

BUILD_TIMESTAMP="$(date --iso-8601=seconds)"

# detect number of system cpus available (select half of cpus for best performance)
BUILD_CPUS=$((`nproc --all` / 2))
let "jobs = $BUILD_CPUS + 1"       # calculate number of jobs (threads + 1)
BUILD_MAKEOPTS="-j${jobs}"

# determine ram available (select min and max)
BUILD_MEMORY_MIN=4096 # we want at least 4G ram for our build
# calculate max memory (set to 1/2 of available memory)
BUILD_MEMORY_MAX=$(((`grep MemTotal /proc/meminfo | awk '{print $2}'` / 1024 / 1024 / 2 + 1 ) * 1024))
let "memory = $BUILD_CPUS * 1024"   # calculate 1G ram for each cpu
BUILD_MEMORY="${memory}"
BUILD_MEMORY=$(($BUILD_MEMORY < $BUILD_MEMORY_MIN ? $BUILD_MEMORY_MIN : $BUILD_MEMORY)) # lower limit (min)
BUILD_MEMORY=$(($BUILD_MEMORY > $BUILD_MEMORY_MAX ? $BUILD_MEMORY_MAX : $BUILD_MEMORY)) # upper limit (max)

BUILD_BOX_MAJOR_VERSION=`echo $BUILD_BOX_FUNTOO_VERSION | sed -e 's/\.//g'`
BUILD_BOX_VERSION=$BUILD_BOX_MAJOR_VERSION

BUILD_BOX_DESCRIPTION="$BUILD_BOX_NAME"

# TODO extract version from https://build.funtoo.org/index.xml (parse with xmlstarlet?)
BUILD_BOX_RELEASE_VERSION=`echo $BUILD_RELEASE_VERSION_ID | sed -e 's/\-//g'`
BUILD_BOX_RELEASE_VERSION=`echo $BUILD_BOX_RELEASE_VERSION | sed -e 's/20//'`
BUILD_BOX_VERSION=$BUILD_BOX_VERSION.$BUILD_BOX_RELEASE_VERSION

# create build dir
mkdir -p "${BUILD_DIR_BUILD}"

if [ -f "$BUILD_FILE_BUILD_VERSION" ]; then
    BUILD_BOX_VERSION=$(<"$BUILD_FILE_BUILD_VERSION")
else
    # generate build_number
    if [ -z ${BUILD_NUMBER:-} ] ; then
        if [ -f "$BUILD_FILE_BUILD_NUMBER" ]; then
            # read from file and increase by one
            BUILD_NUMBER=$(<"$BUILD_FILE_BUILD_NUMBER")
            BUILD_NUMBER=$((BUILD_NUMBER+1))
        else
            BUILD_NUMBER=0
        fi
        # store for later reuse in file 'build_number'
        echo $BUILD_NUMBER > "$BUILD_FILE_BUILD_NUMBER"
        BUILD_BOX_VERSION=$BUILD_BOX_VERSION.$BUILD_NUMBER
    fi
fi
if [ $# -eq 0 ]; then
    echo "build version => $BUILD_BOX_VERSION"
fi
echo $BUILD_BOX_VERSION > "$BUILD_FILE_BUILD_VERSION"
BUILD_OUTPUT_FILE="${BUILD_DIR_BUILD}/${BUILD_BOX_NAME}-${BUILD_BOX_VERSION}.box"

BUILD_BOX_DESCRIPTION="Funtoo ${BUILD_BOX_FUNTOO_VERSION/^0$/next} ($BUILD_FUNTOO_ARCHITECTURE)<br><br>$BUILD_BOX_NAME version $BUILD_BOX_VERSION ($BUILD_RELEASE_VERSION_ID)"
if [ ! -z ${BUILD_NUMBER+x} ] && [ ! -z ${BUILD_TAG+x} ]; then
    # NOTE: for Jenkins builds we got some additional information: BUILD_NUMBER, BUILD_ID, BUILD_DISPLAY_NAME, BUILD_TAG, BUILD_URL
    BUILD_BOX_DESCRIPTION="$BUILD_BOX_DESCRIPTION build $BUILD_NUMBER ($BUILD_TAG)"
fi

if [[ -f "$BUILD_FILE_BUILD_TIME" && -s "$BUILD_FILE_BUILD_TIME" ]]; then
    BUILD_RUNTIME=`cat "$BUILD_FILE_BUILD_TIME"`
    BUILD_RUNTIME_FANCY="Total build runtime was $BUILD_RUNTIME."
else
    BUILD_RUNTIME="unknown"
    BUILD_RUNTIME_FANCY="Total build runtime was not logged."
fi

BUILD_BOX_DESCRIPTION="$BUILD_BOX_DESCRIPTION<br>created @$BUILD_TIMESTAMP<br>"

# check if in git environment and collect git data (if any)
BUILD_GIT=$(echo `git rev-parse --is-inside-work-tree 2>/dev/null || echo "false"`)
if [ $BUILD_GIT == "true" ]; then
    BUILD_GIT_COMMIT_REPO=`git config --get remote.origin.url`
    BUILD_GIT_COMMIT_BRANCH=`git rev-parse --abbrev-ref HEAD`
    BUILD_GIT_COMMIT_ID=`git rev-parse HEAD`
    BUILD_GIT_COMMIT_ID_SHORT=`git rev-parse --short HEAD`
    BUILD_GIT_COMMIT_ID_HREF="${BUILD_BOX_SOURCES}/tree/${BUILD_GIT_COMMIT_ID}"
    BUILD_GIT_LOCAL_MODIFICATIONS=$(if [ "`git diff --shortstat`" == "" ]; then echo 'false'; else echo 'true'; fi)
    BUILD_BOX_DESCRIPTION="$BUILD_BOX_DESCRIPTION<br>Git repository: $BUILD_GIT_COMMIT_REPO"
    if [ $BUILD_GIT_LOCAL_MODIFICATIONS == "true" ]; then
        BUILD_BOX_DESCRIPTION="$BUILD_BOX_DESCRIPTION<br>This build is in an experimental work-in-progress state. Local modifications have not been committed to Git repository yet.<br>$BUILD_RUNTIME_FANCY"
    else
        BUILD_BOX_DESCRIPTION="$BUILD_BOX_DESCRIPTION<br>This build is based on branch $BUILD_GIT_COMMIT_BRANCH (commit id <a href=\\\"$BUILD_GIT_COMMIT_ID_HREF\\\">$BUILD_GIT_COMMIT_ID_SHORT</a>).<br>$BUILD_RUNTIME_FANCY"
    fi
else
    BUILD_BOX_DESCRIPTION="$BUILD_BOX_DESCRIPTION<br>Origin source code: $BUILD_BOX_SOURCES"
    BUILD_BOX_DESCRIPTION="$BUILD_BOX_DESCRIPTION<br>This build is not version controlled yet.<br>$BUILD_RUNTIME_FANCY"
fi

if [ $# -eq 0 ]; then
    title "BUILD SETTINGS"
    if [ "$ANSI" = "true" ]; then
        env | grep BUILD_ | sort | awk -F"=" '{ printf("'${white}${bold}'%.40s '${default}'%s\n",  $1 "'${dark_grey}'........................................'${default}'" , $2) }'
    else
      env | grep BUILD_ | sort | awk -F"=" '{ printf("%.40s %s\n",  $1 "........................................" , $2) }'
    fi
    title_divider
fi
