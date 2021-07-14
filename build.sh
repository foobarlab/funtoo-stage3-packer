#!/bin/bash -e

start=`date +%s`

echo "Executing $0 ..."

. config.sh quiet

require_commands vagrant packer wget sha256sum pv

echo
echo "=========================================================================="
echo
echo "                    Building box '$BUILD_BOX_NAME'"
echo
echo "=========================================================================="
echo

echo ">>> Looking for '$BUILD_SYSRESCUECD_FILE' ..."
if [ -f "$BUILD_SYSRESCUECD_FILE" ]; then
	echo "'$BUILD_SYSRESCUECD_FILE' found. Skipping download ..."
else
    echo "'$BUILD_SYSRESCUECD_FILE' NOT found. Starting download ..."
    wget -c --content-disposition "https://sourceforge.net/projects/systemrescuecd/files/sysresccd-x86/$BUILD_SYSRESCUECD_VERSION/$BUILD_SYSRESCUECD_FILE/download"
	if [ $? -ne 0 ]; then
    	echo "Could not download '$BUILD_SYSRESCUECD_FILE'. Exit code from wget was $?."
    	exit 1
    fi
fi

echo ">>> Checking '$BUILD_SYSRESCUECD_FILE' ..."
BUILD_SYSRESCUECD_LOCAL_HASH=$(pv $BUILD_SYSRESCUECD_FILE | sha256sum | grep -o '^\S\+')
if [ "$BUILD_SYSRESCUECD_LOCAL_HASH" == "$BUILD_SYSRESCUECD_REMOTE_HASH" ]; then
    echo "'$BUILD_SYSRESCUECD_FILE' checksums matched. Proceeding ..."
else
	# FIXME: let the user decide to delete and try downloading again
    echo "'$BUILD_SYSRESCUECD_FILE' checksum did NOT match with expected checksum. The file is possibly corrupted, please delete it and try again."
    exit 1
fi

# FIXME: downloading stage3-latest is not relieable
#BUILD_STAGE3_URL="$BUILD_FUNTOO_DOWNLOADPATH/$BUILD_STAGE3_FILE"
BUILD_STAGE3_URL="$BUILD_FUNTOO_DOWNLOADPATH/${BUILD_RELEASE_VERSION_ID}/stage3-intel64-nehalem-${BUILD_BOX_FUNTOO_VERSION}-release-std-${BUILD_RELEASE_VERSION_ID}.tar.xz"

echo ">>> Looking for '$BUILD_STAGE3_FILE' ..."
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
        rm ./$BUILD_STAGE3_FILE || true
        echo "Resetting 'build_number' ..."
        rm ./build_number || true
    fi
else
    echo "'$BUILD_STAGE3_FILE' not found."
    BUILD_DOWNLOAD_STAGE3=true
fi

if [ "$BUILD_DOWNLOAD_STAGE3" = true ]; then
    echo "Starting download ..."
    wget -c $BUILD_STAGE3_URL -O $BUILD_STAGE3_FILE
	if [ $? -ne 0 ]; then
    	echo "Could not download '$BUILD_STAGE3_URL'. Exit code from wget was $?."
    	exit $?
    fi
    echo "Deleting possibly outdated release info ..."
	rm -f ./release || true
fi

echo ">>> Looking for release info ..."
if [ ! -f ./release ]; then
	echo "Extracting stage3 release info ..."
	tar -xvf $BUILD_STAGE3_FILE ./etc/os-release -O > ./release
else
	echo "Skipping extraction of stage3 release info. Already extracted."
fi

. config.sh quiet

echo ">>> Checking '$BUILD_STAGE3_FILE' ..."
BUILD_HASH_URL="${BUILD_FUNTOO_DOWNLOADPATH}/${BUILD_RELEASE_VERSION_ID}/stage3-intel64-nehalem-${BUILD_BOX_FUNTOO_VERSION}-release-std-${BUILD_RELEASE_VERSION_ID}.tar.xz.hash.txt"
BUILD_HASH_FILE="${BUILD_STAGE3_FILE}.hash.txt"

if [ -f "$BUILD_HASH_FILE" ]; then
	rm -f "$BUILD_HASH_FILE"
fi

if [ ! -f ./${BUILD_HASH_FILE} ]; then
	echo "Downloading hash of stage3 file ..."
	wget ${BUILD_HASH_URL} -O ./${BUILD_HASH_FILE}
fi

echo ">>> Comparing hash sums ..."
BUILD_STAGE3_LOCAL_HASH=$(pv $BUILD_STAGE3_FILE | sha256sum | grep -o '^\S\+')
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

echo "All preparations done."

. config.sh

# do not build an already existing release on vagrant cloud by default

if [ ! $# -eq 0 ]; then
	BUILD_SKIP_VERSION_CHECK=true
else
	BUILD_SKIP_VERSION_CHECK=false
fi

if [ "$BUILD_SKIP_VERSION_CHECK" = false ]; then
	
	. vagrant_cloud_token.sh
	
	# check version match on cloud and abort if same
	echo "Comparing local and cloud version ..."
	# FIXME check if box already exists (should give us a 200 HTTP response, if not we will get a 404)
	latest_cloud_version=$( \
	curl -sS \
	  --header "Authorization: Bearer $VAGRANT_CLOUD_TOKEN" \
	  https://app.vagrantup.com/api/v1/box/$BUILD_BOX_USERNAME/$BUILD_BOX_NAME \
	)
	
	latest_cloud_version=$(echo $latest_cloud_version | jq .current_version.version | tr -d '"')
	echo
	echo "Latest cloud version..: $latest_cloud_version"
	echo "This version..........: $BUILD_BOX_VERSION"
	echo
	
  if [[ $BUILD_BOX_VERSION = $latest_cloud_version ]]; then
		echo "An equal version number already exists. Hint: run './clean.sh' and try again. This will increment your build number automatically."
		exit 0
	else 
	  version_too_small=`version_lt $BUILD_BOX_VERSION $latest_cloud_version && echo "true" || echo "false"`
	  if [[ "$version_too_small" = "true" ]]; then
      printf "\033[1;33mWarning! This version is smaller than the cloud version!\033[0;37m\n\n"
    fi
	  echo "Looks like we have an unreleased version to provide. Proceeding build ..."
	fi

else
	echo "Skipped cloud version check."
fi

cp $BUILD_STAGE3_FILE ./scripts
cp ./release ./scripts/.release_$BUILD_BOX_NAME

export PACKER_LOG_PATH="$PWD/packer.log"
export PACKER_LOG="1"
packer validate virtualbox.json
packer build -force -on-error=abort virtualbox.json

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
    echo "Halting '$BUILD_BOX_NAME' ..."
    vagrant halt
    # TODO vboxmanage modifymedium --compact <path to vdi>
    echo "Exporting base box ..."
    # TODO package additional optional files with --include
    # TODO use configuration values inside template (BUILD_BOX_MEMORY, etc.)
    vagrant package --vagrantfile "Vagrantfile.template" --output "$BUILD_OUTPUT_FILE"
    echo "Removing temporary box file ..."
    rm -f  "$BUILD_OUTPUT_FILE_TEMP"
    # FIXME create sha1 checksum? and save to file for later comparison (include in build description?)
else
    echo "There is no box file '$BUILD_OUTPUT_FILE_TEMP' in the current directory."
    exit 1
fi

end=`date +%s`
runtime=$((end-start))
hours=$((runtime / 3600));
minutes=$(( (runtime % 3600) / 60 ));
seconds=$(( (runtime % 3600) % 60 ));
echo "$hours hours $minutes minutes $seconds seconds" >> build_time
echo "Total build runtime was $hours hours $minutes minutes $seconds seconds."
