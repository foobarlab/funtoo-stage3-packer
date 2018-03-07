#!/bin/bash -e

command -v packer >/dev/null 2>&1 || { echo "Command 'packer' required but it's not installed.  Aborting." >&2; exit 1; }
command -v wget >/dev/null 2>&1 || { echo "Command 'wget' required but it's not installed.  Aborting." >&2; exit 1; }
command -v sha256sum >/dev/null 2>&1 || { echo "Command 'sha256sum' required but it's not installed.  Aborting." >&2; exit 1; }

SYSTEMRESCUECD_VERSION="5.2.1"
export SYSTEMRESCUECD_REMOTE_HASH="d76d9444a73ce2127e489f54b0ce1cb9057ae470459dc3fb32e8c916f7cbfe2e"
export SYSTEMRESCUECD_FILE="systemrescuecd-x86-$SYSTEMRESCUECD_VERSION.iso"

if [ -f "$SYSTEMRESCUECD_FILE" ]
then
    echo "'$SYSTEMRESCUECD_FILE' found. Skipping download ..."
else
    echo "'$SYSTEMRESCUECD_FILE' NOT found. Starting download ..."
    wget --content-disposition https://sourceforge.net/projects/systemrescuecd/files/sysresccd-x86/$SYSTEMRESCUECD_VERSION/$SYSTEMRESCUECD_FILE/download
fi

SYSTEMRESCUECD_LOCAL_HASH=$(cat $SYSTEMRESCUECD_FILE | sha256sum | grep -o '^\S\+')
if [ "$SYSTEMRESCUECD_LOCAL_HASH" == "$SYSTEMRESCUECD_REMOTE_HASH" ]
then
    echo "'$SYSTEMRESCUECD_FILE' checksums matched. Proceeding ..."
else
    echo "'$SYSTEMRESCUECD_FILE' checksum did NOT match with expected checksum. The file is possibly corrupted, please delete it and try again."
    exit 1
fi

STAGE3_FILE="stage3-latest.tar.xz"
STAGE3_FILE_HASH="$STAGE3_FILE.hash.txt"
STAGE3_URL="http://build.funtoo.org/funtoo-current/x86-64bit/generic_64/$STAGE3_FILE"
STAGE3_HASH_URL="https://build.funtoo.org/funtoo-current/x86-64bit/generic_64/$STAGE3_FILE_HASH"

rm -f "$STAGE3_FILE_HASH"
wget $STAGE3_HASH_URL

if [ -f "$STAGE3_FILE" ]
then
    echo "'$STAGE3_FILE' exists. Skipping download ..."
else
    echo "'$STAGE3_FILE' not found. Starting download ..."
    wget $STAGE3_URL
fi

STAGE3_LOCAL_HASH=$(cat $STAGE3_FILE | sha256sum | grep -o '^\S\+')
STAGE3_REMOTE_HASH=$(cat $STAGE3_FILE_HASH | sed -e 's/^sha256\s//g')

if [ "$STAGE3_LOCAL_HASH" == "$STAGE3_REMOTE_HASH" ]
then
    echo "'$STAGE3_FILE' checksums matched. Proceeding ..."
else
    echo "'$STAGE3_FILE' checksums did NOT match. The file is possibly outdated or corrupted, please delete it and try again."
    exit 1
fi

cp $STAGE3_FILE ./scripts

export PACKER_LOG_PATH="$PWD/packer.log"
export PACKER_LOG="1"

packer build virtualbox.json
