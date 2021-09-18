#!/bin/bash -ue
# vim: ts=4 sw=4 et
# NOTE: Vagrant Cloud API see: https://www.vagrantup.com/docs/vagrant-cloud/api.html

CLOUD_VERSION_CURRENT='Current-version'
CLOUD_VERSION_FOUND='Found-version'

# TODO separate Funtoo next (version 9999.x) and Funtoo 1.4 (version 14.x)

. config.sh quiet

require_commands curl jq

declare -A BUILD_CLOUD_VERSION

cloud_box_info=$( \
  curl -sS -f \
  https://app.vagrantup.com/api/v1/box/$BUILD_BOX_USERNAME/$BUILD_BOX_NAME \
)

# DEBUG
#echo $cloud_box_info | jq

BUILD_CLOUD_VERSION[$CLOUD_VERSION_CURRENT]=$(echo $cloud_box_info | jq .current_version.version | tr -d '"')

# DEBUG
#echo "${BUILD_CLOUD_VERSION[$CLOUD_VERSION_CURRENT]} ${BUILD_CLOUD_VERSION[$CLOUD_VERSION_CURRENT]}"

#BUILD_CLOUD_VERSION[$CLOUD_VERSION_FOUND]=$(echo $cloud_box_info | jq .versions[] | jq .version | tr -d '"' | sort -r )
BUILD_CLOUD_VERSION[$CLOUD_VERSION_FOUND]=$(echo $cloud_box_info | jq .versions[] | jq .version | tr -d '"' | sort )
#BUILD_CLOUD_VERSION[$CLOUD_VERSION_FOUND]=$(echo $cloud_box_info | jq .versions[] | jq .version | tr -d '"' )

#BUILD_BOX_VERSION -> 14
#BUILD_RELEASE -> 1.4-release-std

#BUILD_BOX_VERSION -> 9999
#BUILD_RELEASE -> next

# DEBUG
echo "-------------------------------------------------------------------"
echo "Build major version: $BUILD_BOX_MAJOR_VERSION"
echo "Build version: $BUILD_BOX_VERSION"
#echo "Build release: $BUILD_RELEASE"
echo "-------------------------------------------------------------------"

# iterate all found versions
for version in ${BUILD_CLOUD_VERSION[$CLOUD_VERSION_FOUND]}; do
  step "Processing version '$version' ..."
  
  #todo "check if current '(done)'"
  if [[ $version = ${BUILD_CLOUD_VERSION[$CLOUD_VERSION_CURRENT]} ]]; then
    echo "is-current"
  fi
  
  #todo "compare major version and check release kind '(done)'"
  major_version=$( echo $version | sed -e "s/[^0-9]*\([0-9]*\)[.].*/\1/" )
  case $major_version in
    "9999")
        echo "release-next"
      ;;
    *)
      echo "release-$major_version"
      ;;
  esac

  #todo "check if in scope '(done}'"
  if [ $major_version = $BUILD_BOX_MAJOR_VERSION ]; then
    echo "within-scope"
  else
    echo "out-of-scope"
  fi

  #todo "collect box info '(done)'"
  cloud_box_info_item=$(echo $cloud_box_info | jq '.versions[] | select(.version=="'$version'")')
  #echo $cloud_box_info_item | jq

  #todo "check if active '(done)'"
  cloud_box_info_item_status=$(echo $cloud_box_info_item | jq .status | tr -d '"')
  echo "status-$cloud_box_info_item_status"

  #todo "check if higher/lower than build version '(done)'"
  #echo "version: $version"
  #echo "build version: $BUILD_BOX_VERSION"

  if [[ $BUILD_BOX_VERSION == $version ]]; then
    echo "equal-version"
  elif `version_lt $version $BUILD_BOX_VERSION`; then
    echo "lower-version"
  elif `version_lt $BUILD_BOX_VERSION $version`; then
    echo "higher-version"
  fi

done

# DEBUG
echo "==================================================================="
echo "DEBUG: Variable BUILD_CLOUD_VERSION (key: value):"
echo "==================================================================="
#echo "DEBUG: values -> ${BUILD_CLOUD_VERSION[@]}"   # values
#echo "DEBUG: keys -> ${!BUILD_CLOUD_VERSION[*]}"  # keys
for key in ${!BUILD_CLOUD_VERSION[*]}; do
  #echo "${key//\-/ }: ${BUILD_CLOUD_VERSION[$key]}"
  for value in ${BUILD_CLOUD_VERSION[$key]}; do
    echo "${key//\-/ }: $value"
  done
done