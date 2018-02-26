#!/bin/bash -e

echo "Running in dir: $(pwd)"

# configure systemrescuecd version + sha256sum here (also check virtualbox.json fields iso_checksum and iso_url)
VERSION="5.2.1"
SHA256SUM="d76d9444a73ce2127e489f54b0ce1cb9057ae470459dc3fb32e8c916f7cbfe2e"

command -v packer >/dev/null 2>&1 || { echo "Command 'packer' required but it's not installed.  Aborting." >&2; exit 1; }
command -v wget >/dev/null 2>&1 || { echo "Command 'wget' required but it's not installed.  Aborting." >&2; exit 1; }
command -v sha256sum >/dev/null 2>&1 || { echo "Command 'sha256sum' required but it's not installed.  Aborting." >&2; exit 1; }

FILE="systemrescuecd-x86-$VERSION.iso"
if [ -f "$FILE" ]
then
    echo "$FILE found. skipping download ..."
else
    echo "$FILE NOT found. start downloading from sourceforge ..."
    wget --content-disposition https://sourceforge.net/projects/systemrescuecd/files/sysresccd-x86/$VERSION/$FILE/download
fi

FILE_HASH=$(cat $FILE | sha256sum | grep -o '^\S\+')
if [ "$SHA256SUM" == "$FILE_HASH" ]
then
    echo "sha256sum matched. proceeding ..."
else
    echo "sha256sum did NOT match. file is possibly corrupted, please delete $FILE and try again."
    exit 1
fi

STAGE3_FILE="stage3-latest.tar.xz"
STAGE3_URL="http://build.funtoo.org/funtoo-current/x86-64bit/generic_64/$STAGE3_FILE"
STAGE3_HASH_URL="https://build.funtoo.org/funtoo-current/x86-64bit/generic_64/$STAGE3_FILE.hash.txt"

rm -f "$STAGE3_FILE.hash.txt"
wget $STAGE3_HASH_URL

if [ -f "$STAGE3_FILE" ]
then
    echo "$STAGE3_FILE exists. skipping download ..."
else
    echo "$STAGE3_FILE not found. will try to download ..."
    wget $STAGE3_URL
fi

STAGE3_FILE_HASH=$(cat $STAGE3_FILE | sha256sum | grep -o '^\S\+')
STAGE3_HASH=$(cat $STAGE3_FILE.hash.txt | sed -e 's/^sha256\s//g')

if [ "$STAGE3_FILE_HASH" == "$STAGE3_HASH" ]
then
    echo "sha256sum matched. proceeding ..."
else
    echo "sha256sum did NOT match. file is possibly outdated or corrupted, please delete $STAGE3_FILE and try again."
    exit 1
fi

cp $STAGE3_FILE ./scripts

packer build virtualbox.json
