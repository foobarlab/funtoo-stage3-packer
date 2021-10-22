#!/bin/bash -ue
# vim: ts=4 sw=4 et

start=`date +%s`

. config.sh quiet

header "Building box '$BUILD_BOX_NAME'"
require_commands vagrant packer wget jq sha256sum pv

highlight "Looking for '$BUILD_SYSRESCUECD_FILE' ..."
if [ -f "$BUILD_SYSRESCUECD_FILE" ]; then
    info "'$BUILD_SYSRESCUECD_FILE' found. Skipping download ..."
else
    warn "'$BUILD_SYSRESCUECD_FILE' NOT found. Starting download ..."
    wget -c --content-disposition "https://sourceforge.net/projects/systemrescuecd/files/sysresccd-x86/$BUILD_SYSRESCUECD_VERSION/$BUILD_SYSRESCUECD_FILE/download"
    if [ $? -ne 0 ]; then
        error "Could not download '$BUILD_SYSRESCUECD_FILE'. Exit code from wget was $?."
        exit 1
    fi
fi

highlight "Checking '$BUILD_SYSRESCUECD_FILE' ..."
BUILD_SYSRESCUECD_LOCAL_HASH=$(pv $BUILD_SYSRESCUECD_FILE | sha256sum | grep -o '^\S\+')
if [ "$BUILD_SYSRESCUECD_LOCAL_HASH" == "$BUILD_SYSRESCUECD_REMOTE_HASH" ]; then
    info "'$BUILD_SYSRESCUECD_FILE' checksums matched. Proceeding ..."
else
    # FIXME: let the user decide to delete and try downloading again
    error "'$BUILD_SYSRESCUECD_FILE' checksum did NOT match with expected checksum. The file is possibly corrupted, please delete it and try again."
    exit 1
fi

BUILD_STAGE3_URL="$BUILD_FUNTOO_DOWNLOADPATH/${BUILD_RELEASE_VERSION_ID}/${BUILD_FUNTOO_STAGE3}-${BUILD_RELEASE_VERSION_ID}.tar.xz"

highlight "Looking for '$BUILD_STAGE3_FILE' ..."
if [ -f "$BUILD_STAGE3_FILE" ]; then
    BUILD_REMOTE_TIMESTAMP=$(date -d "$(curl -s -v -X HEAD $BUILD_STAGE3_URL 2>&1 | grep '^< last-modified:' | sed 's/^.\{17\}//')" +%s)
    BUILD_LOCAL_TIMESTAMP=$(date -d "$(find $BUILD_STAGE3_FILE -exec stat \{} --printf="%y\n" \;)" +%s)
    BUILD_COMPARE_TIMESTAMP=$(( $BUILD_REMOTE_TIMESTAMP - $BUILD_LOCAL_TIMESTAMP ))
    if [[ $BUILD_COMPARE_TIMESTAMP -eq 0 ]]; then
        info "'$BUILD_STAGE3_FILE' already exists and seems up-to-date."
        BUILD_DOWNLOAD_STAGE3=false
    else
        warn "'$BUILD_STAGE3_FILE' already exists but seems outdated:"
        echo "-> local : $(date -d @${BUILD_LOCAL_TIMESTAMP})"
        echo "-> remote: $(date -d @${BUILD_REMOTE_TIMESTAMP})"
        BUILD_DOWNLOAD_STAGE3=true
        step "Deleting '$BUILD_STAGE3_FILE' ..."
        rm ./$BUILD_STAGE3_FILE || true
        step "Resetting 'build_number' ..."
        rm ./build_number || true
    fi
else
    warn "'$BUILD_STAGE3_FILE' not found."
    BUILD_DOWNLOAD_STAGE3=true
fi

if [ "$BUILD_DOWNLOAD_STAGE3" = true ]; then
    highlight "Starting download of stage3 tarball ..."
    wget -c $BUILD_STAGE3_URL -O $BUILD_STAGE3_FILE
    if [ $? -ne 0 ]; then
        error "Could not download '$BUILD_STAGE3_URL'. Exit code from wget was $?."
        exit $?
    fi
fi

. config.sh quiet

highlight "Checking '$BUILD_STAGE3_FILE' ..."
BUILD_HASH_URL="${BUILD_FUNTOO_DOWNLOADPATH}/${BUILD_RELEASE_VERSION_ID}/${BUILD_FUNTOO_STAGE3}-${BUILD_RELEASE_VERSION_ID}.tar.xz.hash.txt"
BUILD_HASH_FILE="${BUILD_STAGE3_FILE}.hash.txt"

if [ -f "$BUILD_HASH_FILE" ]; then
    rm -f "$BUILD_HASH_FILE"
fi

if [ ! -f ./${BUILD_HASH_FILE} ]; then
    step "Downloading hash of stage3 file ..."
    wget ${BUILD_HASH_URL} -O ./${BUILD_HASH_FILE}
fi

highlight "Comparing hash sums ..."
BUILD_STAGE3_LOCAL_HASH=$(pv $BUILD_STAGE3_FILE | sha256sum | grep -o '^\S\+')
BUILD_STAGE3_REMOTE_HASH=$(cat $BUILD_HASH_FILE | sed -e 's/^sha256\s//g')

if [ "$BUILD_STAGE3_LOCAL_HASH" == "$BUILD_STAGE3_REMOTE_HASH" ]; then
    info "'$BUILD_STAGE3_FILE' checksums matched. Proceeding ..."
else
    warn "'$BUILD_STAGE3_FILE' checksums did NOT match. The file is possibly outdated or corrupted."
    read -p "Do you want to delete it and try again (Y/n)? " choice
    case "$choice" in
      n|N ) echo "Canceled by user."
            exit 1
            ;;
      * ) step "Deleting '$BUILD_STAGE3_FILE' ..."
          rm -f $BUILD_STAGE3_FILE
          exec $0
          exit 0
          ;;
    esac
fi

. distfiles.sh quiet

# do not build an already existing release on vagrant cloud by default

if [ ! $# -eq 0 ]; then
    BUILD_SKIP_VERSION_CHECK=true
else
    BUILD_SKIP_VERSION_CHECK=false
fi

if [ "$BUILD_SKIP_VERSION_CHECK" = false ]; then

    # FIXME move to cloud_version.sh?
    # check version match on cloud and abort if same
    highlight "Comparing local and cloud version ..."
    # FIXME check if box already exists (should give us a 200 HTTP response, if not we will get a 404)
    latest_cloud_version=$( \
    curl -sS \
      https://app.vagrantup.com/api/v1/box/$BUILD_BOX_USERNAME/$BUILD_BOX_NAME \
    )

    latest_cloud_version=$(echo $latest_cloud_version | jq .current_version.version | tr -d '"')
    echo
    info "Latest cloud version..: '${latest_cloud_version}'"
    info "This version..........: '${BUILD_BOX_VERSION}'"
    echo

    # TODO automatically generate initial build number?

    # FIXME replace with cloud_version.sh?
    if [[ "$BUILD_BOX_VERSION" = "$latest_cloud_version" ]]; then
        error "An equal version number already exists, please run './clean.sh' to increment your build number and try again."
        todo "Automatically increase build number?"
        exit 1
    else
    	# FIXME replace with cloud_version.sh?
        version_too_small=`version_lt $BUILD_BOX_VERSION $latest_cloud_version && echo "true" || echo "false"`
        if [[ "$version_too_small" = "true" ]]; then
            warn "This version is smaller than the cloud version!"
            todo "Automatically increase build_number"
        fi
        result "Looks like we build an unreleased version."
    fi
else
    warn "Skipped cloud version check."
fi


final "All preparations done."

. config.sh

step "Invoking packer ..."
export PACKER_LOG_PATH="$PWD/packer.log"
export PACKER_LOG="1"

if [ $PACKER_LOG ]; then
    info "Logging Packer output to '$PACKER_LOG_PATH' ..."
fi

# TODO upgrade to packer hcl template
step "Invoking Packer build configuration '$PWD/packer/virtualbox.json' ..."
packer validate "$PWD/packer/virtualbox.json"
packer build -force -on-error=abort "$PWD/packer/virtualbox.json"

step "Removing temporary stage3 file ..."
rm -f ./scripts/$BUILD_STAGE3_FILE

title "OPTIMIZING BOX SIZE"

if [ -f "$BUILD_OUTPUT_FILE_TEMP" ]; then
    step "Suspending any running instances ..."
    vagrant suspend
    step "Destroying current box ..."
    vagrant destroy -f || true
    step "Removing '$BUILD_BOX_NAME' ..."
    vagrant box remove -f "$BUILD_BOX_NAME" 2>/dev/null || true
    step "Adding '$BUILD_BOX_NAME' ..."
    vagrant box add -f --name "$BUILD_BOX_NAME" "$BUILD_OUTPUT_FILE_TEMP"
    step "Powerup and provision '$BUILD_BOX_NAME' ..."
    vagrant --provision up || { echo "Unable to startup '$BUILD_BOX_NAME'."; exit 1; }
    step "Halting '$BUILD_BOX_NAME' ..."
    vagrant halt
    # TODO vboxmanage modifymedium disk --compact <path to vdi> ?
    step "Exporting base box to '$BUILD_OUTPUT_FILE' ..."
    # TODO package additional optional files with --include ?
    # TODO use configuration values inside template (BUILD_BOX_MEMORY, etc.)
    #vagrant package --vagrantfile "Vagrantfile.template" --output "$BUILD_OUTPUT_FILE"
    vagrant package --output "$BUILD_OUTPUT_FILE"
    step "Removing temporary box file ..."
    rm -f  "$BUILD_OUTPUT_FILE_TEMP"
    # FIXME create sha1 checksum? and save to file for later comparison (include in build description?)
else
    error "There is no box file '$BUILD_OUTPUT_FILE_TEMP' in the current directory."
    exit 1
fi

end=`date +%s`
runtime=$((end-start))
hours=$((runtime / 3600));
minutes=$(( (runtime % 3600) / 60 ));
seconds=$(( (runtime % 3600) % 60 ));
echo "$hours hours $minutes minutes $seconds seconds" >> build_time
result "Build runtime was $hours hours $minutes minutes $seconds seconds."
