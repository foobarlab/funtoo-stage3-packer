#!/bin/bash -e

echo "Executing $0 ..."

. config.sh quiet

command -v vagrant >/dev/null 2>&1 || { echo "Command 'vagrant' required but it's not installed.  Aborting." >&2; exit 1; }
command -v packer >/dev/null 2>&1 || { echo "Command 'packer' required but it's not installed.  Aborting." >&2; exit 1; }
command -v wget >/dev/null 2>&1 || { echo "Command 'wget' required but it's not installed.  Aborting." >&2; exit 1; }
command -v sha256sum >/dev/null 2>&1 || { echo "Command 'sha256sum' required but it's not installed.  Aborting." >&2; exit 1; }

if [ -f "$BUILD_SYSTEMRESCUECD_FILE" ]; then
	echo "'$BUILD_SYSTEMRESCUECD_FILE' found. Skipping download ..."
else
    echo "'$BUILD_SYSTEMRESCUECD_FILE' NOT found. Starting download ..."
    wget --content-disposition "https://sourceforge.net/projects/systemrescuecd/files/sysresccd-x86/$BUILD_SYSTEMRESCUECD_VERSION/$BUILD_SYSTEMRESCUECD_FILE/download"
	if [ $? -ne 0 ]; then
    	echo "Could not download '$BUILD_SYSTEMRESCUECD_FILE'. Exit code from wget was $?."
    	exit 1
    fi
fi

BUILD_SYSTEMRESCUECD_LOCAL_HASH=$(cat $BUILD_SYSTEMRESCUECD_FILE | sha256sum | grep -o '^\S\+')
if [ "$BUILD_SYSTEMRESCUECD_LOCAL_HASH" == "$BUILD_SYSTEMRESCUECD_REMOTE_HASH" ]; then
    echo "'$BUILD_SYSTEMRESCUECD_FILE' checksums matched. Proceeding ..."
else
	# FIXME: let the user decide to delete and try downloading again
    echo "'$BUILD_SYSTEMRESCUECD_FILE' checksum did NOT match with expected checksum. The file is possibly corrupted, please delete it and try again."
    exit 1
fi

BUILD_STAGE3_URL="$BUILD_FUNTOO_DOWNLOADPATH/$BUILD_STAGE3_FILE"

if [ -f "$BUILD_STAGE3_FILE" ]; then
    BUILD_REMOTE_TIMESTAMP=$(date -d "$(curl -s -v -X HEAD $BUILD_STAGE3_URL 2>&1 | grep '^< last-modified:' | sed 's/^.\{17\}//')" +%s)
    BUILD_LOCAL_TIMESTAMP=$(date -d "$(find $BUILD_STAGE3_FILE -exec stat \{} --printf="%y\n" \;)" +%s)
    BUILD_COMPARE_TIMESTAMP=$(( $BUILD_REMOTE_TIMESTAMP - $BUILD_LOCAL_TIMESTAMP ))
    if [[ $BUILD_COMPARE_TIMESTAMP -eq 0 ]]; then
        echo "'$BUILD_STAGE3_FILE' already exists and seems up-to-date."
        BUILD_DOWNLOAD_STAGE3=false
    else
        echo "'$BUILD_STAGE3_FILE' already exists but seems outdated:"    
        echo "-> local : $(date -d @${BUILD_LOCAL_TIMESTAMP})"
        echo "-> remote: $(date -d @${BUILD_REMOTE_TIMESTAMP})"
        BUILD_DOWNLOAD_STAGE3=true
        echo "Deleting '$BUILD_STAGE3_FILE' ..."
        rm ./$BUILD_STAGE3_FILE
    fi
else
    echo "'$BUILD_STAGE3_FILE' not found."
    BUILD_DOWNLOAD_STAGE3=true
fi

if [ "$BUILD_DOWNLOAD_STAGE3" = true ]; then
    echo "Starting download ..."
    wget $BUILD_STAGE3_URL
	if [ $? -ne 0 ]; then
    	echo "Could not download '$BUILD_STAGE3_URL'. Exit code from wget was $?."
    	exit 1
    fi
    echo "Deleting possibly outdated release info ..."
	rm -f ./release
fi

if [ ! -f ./release ]; then
	echo "Extracting stage3 release info ..."
	tar -xvf $BUILD_STAGE3_FILE ./etc/os-release -O > ./release
else
	echo "Skipping extraction of stage3 release info. Already extracted."
fi

. config.sh

BUILD_HASH_URL="${BUILD_FUNTOO_DOWNLOADPATH}/${BUILD_RELEASE_VERSION_ID}/stage3-intel64-nehalem-${BUILD_BOX_FUNTOO_VERSION}-release-std-${BUILD_RELEASE_VERSION_ID}.tar.xz.hash.txt"
BUILD_HASH_FILE="${BUILD_STAGE3_FILE}.hash.txt"

if [ -f "$BUILD_HASH_FILE" ]; then
	rm -f "$BUILD_HASH_FILE"
fi

if [ ! -f ./${BUILD_HASH_FILE} ]; then
	echo "Downloading hash of stage3 file ..."
	wget ${BUILD_HASH_URL} -O ./${BUILD_HASH_FILE}
fi

BUILD_STAGE3_LOCAL_HASH=$(cat $BUILD_STAGE3_FILE | sha256sum | grep -o '^\S\+')
BUILD_STAGE3_REMOTE_HASH=$(cat $BUILD_HASH_FILE | sed -e 's/^sha256\s//g')

if [ "$BUILD_STAGE3_LOCAL_HASH" == "$BUILD_STAGE3_REMOTE_HASH" ]; then
    echo "'$BUILD_STAGE3_FILE' checksums matched. Proceeding ..."
else
    echo "'$BUILD_STAGE3_FILE' checksums did NOT match. The file is possibly outdated or corrupted."
	read -p "Do you want to delete it and try again (Y/n)? " choice
	case "$choice" in 
	  n|N ) echo "Canceled by user."
	  		exit 1
	        ;;
	  * ) echo "Deleting '$BUILD_STAGE3_FILE' ..."
	      rm -f $BUILD_STAGE3_FILE
	      echo "Cleanup stage3 release info ..."
	      rm -f ./release
	      exec $0
	      ;;
	esac
fi

. config.sh

# as we do not want to build an already existing release on vagrant cloud automatically we better ask the user
	
if [ $# -eq 0 ]; then
	BUILD_SKIP_VERSION_CHECK=true
else
	BUILD_SKIP_VERSION_CHECK=false
fi

if [ "$BUILD_SKIP_VERSION_CHECK" = false ]; then
	
	. vagrant_cloud_token.sh
	
	# check version match on cloud and abort if same
	echo "Comparing local and cloud version ..."
	# FIXME check if box already exists (should give us a 200 HTTP response, if not we will get a 404)
	LATEST_CLOUD_VERSION=$( \
	curl -sS \
	  --header "Authorization: Bearer $VAGRANT_CLOUD_TOKEN" \
	  https://app.vagrantup.com/api/v1/box/$BUILD_BOX_USERNAME/$BUILD_BOX_NAME \
	)
	
	LATEST_CLOUD_VERSION=$(echo $LATEST_CLOUD_VERSION | jq .current_version.version | tr -d '"')
	echo "Our latest version: $BUILD_BOX_VERSION"
	echo "Latest cloud version: $LATEST_CLOUD_VERSION"
	
	if [[ $BUILD_BOX_VERSION = $LATEST_CLOUD_VERSION ]]; then
		echo "Same version already exists. Aborting build."
		exit 0
	else 
		echo "Looks like we got a new version available. Proceeding build ..."
	fi

else
	echo "Skipping cloud version check ..."
fi

cp $BUILD_STAGE3_FILE ./scripts
cp ./release ./scripts/.release_$BUILD_BOX_NAME

export PACKER_LOG_PATH="$PWD/packer.log"
export PACKER_LOG="1"
packer validate virtualbox.json
packer build virtualbox.json

rm -f ./scripts/$BUILD_STAGE3_FILE

echo "------------------------------------------------------------------------"
echo "                         OPTIMIZING BOX SIZE"
echo "------------------------------------------------------------------------"

if [ -f "$BUILD_OUTPUT_FILE_TEMP" ]; then
    echo "Suspending any running instances ..."
    vagrant suspend
    echo "Destroying current box ..."
    vagrant destroy -f || true
    echo "Removing '$BUILD_BOX_NAME' ..."
    vagrant box remove -f "$BUILD_BOX_NAME" 2>/dev/null || true
    echo "Adding '$BUILD_BOX_NAME' ..."
    vagrant box add --name "$BUILD_BOX_NAME" "$BUILD_OUTPUT_FILE_TEMP"
    echo "Powerup and provision '$BUILD_BOX_NAME' ..."
    vagrant --provision up || { echo "Unable to startup '$BUILD_BOX_NAME'."; exit 1; }
    echo "Exporting base box ..."
    vagrant package --output "$BUILD_OUTPUT_FILE"
	echo "Removing temporary box file ..."
	rm -f  "$BUILD_OUTPUT_FILE_TEMP"
else
    echo "There is no box file '$BUILD_OUTPUT_FILE_TEMP' in the current directory."
    exit 1
fi
