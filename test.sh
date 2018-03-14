#!/bin/bash -ue

. config.sh

if [ -f "$BUILD_OUTPUT_FILE" ]
then
	echo "Suspending any running instances ..."
	vagrant suspend
	echo "Destroying current box ..."
	vagrant destroy -f || true
	echo "Removing '$BUILD_BOX_NAME' ..."
	vagrant box remove -f "$BUILD_BOX_NAME" 2>/dev/null || true
	echo "Adding '$BUILD_BOX_NAME' ..."
	vagrant box add --name "$BUILD_BOX_NAME" "$BUILD_OUTPUT_FILE"
	echo "Powerup '$BUILD_BOX_NAME' ..."
	vagrant up --no-provision || true
	echo "Establishing SSH connection to '$BUILD_BOX_NAME' ..."
	vagrant ssh
else
	echo "There is no box file '$BUILD_OUTPUT_FILE' in the current directory. Please run './build.sh' before to build the box."
	exit 1
fi
