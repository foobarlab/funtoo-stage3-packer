#!/bin/bash -ue
# vim: ts=4 sw=4 et
# NOTE: Vagrant Cloud API see: https://www.vagrantup.com/docs/vagrant-cloud/api.html

. config.sh quiet

require_commands curl jq

BUILD_CLOUD_BOX_INFO=$( \
  curl -sS -f \
  https://app.vagrantup.com/api/v1/box/$BUILD_BOX_USERNAME/$BUILD_BOX_NAME \
)

# DEBUG
echo $BUILD_CLOUD_BOX_INFO | jq

LATEST_CLOUD_VERSION=$(echo $BUILD_CLOUD_BOX_INFO | jq .current_version.version | tr -d '"')

# DEBUG
echo "Latest: $LATEST_CLOUD_VERSION"

EXISTING_CLOUD_VERSIONS=$(echo $BUILD_CLOUD_BOX_INFO | jq .versions[] | jq .version | tr -d '"' | sort -r )

# DEBUG
echo "Existing: $EXISTING_CLOUD_VERSIONS"

# TODO separate Funtoo next (version 9999.x) and Funtoo 1.4 (version 14.x)
