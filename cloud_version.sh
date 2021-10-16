#!/bin/bash -ue
# vim: ts=4 sw=4 et
# NOTE: Vagrant Cloud API see: https://www.vagrantup.com/docs/vagrant-cloud/api.html

CLOUD_VERSION_CURRENT='Current-version'
CLOUD_VERSION_FOUND='Found-version'

. config.sh quiet

require_commands curl jq #bc

declare -A BUILD_CLOUD_VERSION

# TODO build.sh: get latest cloud version
# TODO count boxes: release separated

decode() {
  # DEBUG
  echo -n "decoding bitfield: $1: "
  echo `bc <<<'obase=2; '${1}''`
}

step "Checking availability ..."
cloud_box_info_availibility=$( \
  curl -sS -w "%{http_code}" -o /dev/null \
  https://app.vagrantup.com/api/v1/box/$BUILD_BOX_USERNAME/$BUILD_BOX_NAME \
)
case "$cloud_box_info_availibility" in
  200) result `printf "Received: HTTP $cloud_box_info_availibility ==> Found\n"` ;;
  404) warn `printf "Received HTTP $cloud_box_info_availibility ==> Not found\n"` ;;
  *) error `printf "Received: HTTP $cloud_box_info_availibility ==> Unhandled status code while trying to get box meta info, aborting.\n"`; exit 1 ;;
esac

step "Requesting cloud box meta info ..."
cloud_box_info=$( \
  curl -sS -f \
  https://app.vagrantup.com/api/v1/box/$BUILD_BOX_USERNAME/$BUILD_BOX_NAME \
)
BUILD_CLOUD_VERSION[$CLOUD_VERSION_CURRENT]=$(echo $cloud_box_info | jq .current_version.version | tr -d '"')
BUILD_CLOUD_VERSION[$CLOUD_VERSION_FOUND]=$(echo $cloud_box_info | jq .versions[] | jq .version | tr -d '"' | sort -r )

# iterate all found versions, populate data
for version in ${BUILD_CLOUD_VERSION[$CLOUD_VERSION_FOUND]}; do
  step "Processing version '$version' ..."
  version_data=""

  # check if found version is current
  if [[ $version = ${BUILD_CLOUD_VERSION[$CLOUD_VERSION_CURRENT]} ]]; then
    version_data="${version_data}is-current "
  fi

  # compare major version and check release kind of found version
  major_version=$( echo $version | sed -e "s/[^0-9]*\([0-9]*\)[.].*/\1/" )
  #case $major_version in
  #  "9999")
  #      version_data="${version_data}release-next "
  #    ;;
  #  *)
  #      version_data="${version_data}release-${major_version} "
  #    ;;
  #esac

  # check if found version is in scope (in par with build version)
  if [ $major_version = $BUILD_BOX_MAJOR_VERSION ]; then
    version_data="${version_data}within-scope "
  else
    version_data="${version_data}out-of-scope "
  fi

  # collect vagrant cloud box info
  cloud_box_info_item=$(echo $cloud_box_info | jq '.versions[] | select(.version=="'$version'")')
  #echo $cloud_box_info_item | jq

  # check if found version is active
  cloud_box_info_item_status=$(echo $cloud_box_info_item | jq .status | tr -d '"')
  version_data="${version_data}status-${cloud_box_info_item_status} "

  # check if found version is higher/lower than build version
  if [[ $BUILD_BOX_VERSION == $version ]]; then
    version_data="${version_data}equal-version "
  elif `version_lt $version $BUILD_BOX_VERSION`; then
    version_data="${version_data}lower-version "
  elif `version_lt $BUILD_BOX_VERSION $version`; then
    version_data="${version_data}higher-version "
  fi

  # TODO convert to bitfield
  # see https://linuxhint.com/bash_operator_examples/
  # see https://www.gnu.org/software/gawk/manual/html_node/Bitwise-Functions.html

  version_data_bitfield=0 #$((0x0))
  for value in $version_data; do
    #echo "Value: '${value}'"
    case $value in
      "is-current" )
        echo "Current version"
        version_data_bitfield=$(( $version_data_bitfield | (1 << 1) ))
        decode $version_data_bitfield
        ;;
      "status-active" )
        echo "Status active"
        version_data_bitfield=$(( $version_data_bitfield | (1 << 2) ))
        decode $version_data_bitfield
        ;;
      "within-scope" )
        echo "Within scope"
        version_data_bitfield=$(( $version_data_bitfield | (1 << 3) ))
        decode $version_data_bitfield
        ;;
      "equal-version" )
        echo "Equal version"
        version_data_bitfield=$(( $version_data_bitfield | (1 << 4) ))
        decode $version_data_bitfield
        ;;
      "lower-version" )
        echo "Lower version"
        version_data_bitfield=$(( $version_data_bitfield | (1 << 5) ))
        decode $version_data_bitfield
        ;;
      * )
        echo "Ignoring value: '$value'"
    esac
  done

  # match rule: 00110 (within scope, version greater) -> warn 
  # match rule: 00111

  ## DEBUG
  #echo -n "bitfield: $version_data_bitfield: "
  #echo `bc <<<'obase=2; '${version_data_bitfield}''`

  ## match rule: ignore when out of scope
  #if [[ " ${array[*]} " =~ " ${value} " ]]; then
  #  # whatever you want to do when array contains value
  #fi
  #
  #if [[ ! " ${array[*]} " =~ " ${value} " ]]; then
  #  # whatever you want to do when array doesn't contain value
  #fi
  #
  #version_match_rule "$version" "in-scope higher_version"

  todo "DEBUG: version-data='${version_data}'"

  if [[ "$version_data" =~ "out-of-scope" ]]; then
    warn "Ignoring 'out-of-scope' version ..."
  else
    #case $version_data in
    #  *)
    #    echo "Catchall: '${version_data}'"
    #esac
    todo "match rules"
  fi

  # assign to global var
  BUILD_CLOUD_VERSION[$version]=$version_data
  export BUILD_CLOUD_VERSION
  unset version_data
done

# DEBUG
echo "==================================================================="
echo "DEBUG: Variable BUILD_CLOUD_VERSION (key: value):"
echo "==================================================================="
#echo "DEBUG: values -> ${BUILD_CLOUD_VERSION[@]}"   # values
#echo "DEBUG: keys -> ${!BUILD_CLOUD_VERSION[*]}"  # keys
for key in ${!BUILD_CLOUD_VERSION[*]}; do
  echo "${key//\-/ }: ${BUILD_CLOUD_VERSION[$key]}"
  #for value in ${BUILD_CLOUD_VERSION[$key]}; do
  #  echo "${key//\-/ }: $value"
  #done
done
