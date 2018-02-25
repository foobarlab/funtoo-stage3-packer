#!/bin/bash -ue

BOX_FILE="funtoo-x86_64-generic_64-stage3.box"
BOX_NAME="funtoo-stage3"

if [ -f "$BOX_FILE" ]
then
	echo "Suspending any running instances ..."
	vagrant suspend
	echo "Destroying current box ..."
	vagrant destroy -f || true
	echo "Removing '$BOX_NAME' ..."
	vagrant box remove -f "$BOX_NAME" || true
	echo "Adding '$BOX_NAME' ..."
	vagrant box add --name "$BOX_NAME" "$BOX_FILE"
	echo "Powerup '$BOX_NAME' ..."
	vagrant up || true
	echo "Establishing SSH connection to '$BOX_NAME' ..."
	vagrant ssh
else
	echo "There is no box file \"$BOX_FILE\" in the current directory. Please run './build.sh' to build the box."
	exit 1
fi
