#!/bin/bash -ue

. config.sh

require_commands vagrant

echo "==> Initializing a fresh '$BUILD_BOX_NAME' box ..."

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
else
	echo "There is no box file '$BUILD_OUTPUT_FILE' in the current directory. Please run './build.sh' before to build the box."
	exit 1
fi

echo "Box installed and ready to use. You may now enter './startup.sh' to boot the box."
