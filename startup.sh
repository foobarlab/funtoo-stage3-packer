#!/bin/bash -ue

. config.sh

require_commands vagrant

echo "==> Starting '$BUILD_BOX_NAME' box ..."

echo "Powerup '$BUILD_BOX_NAME' ..."
vagrant up --no-provision || { echo "Unable to startup '$BUILD_BOX_NAME'."; exit 1; }
echo "Establishing SSH connection to '$BUILD_BOX_NAME' ..."
vagrant ssh
