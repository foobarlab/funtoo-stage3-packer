#!/bin/bash -ue

command -v vagrant >/dev/null 2>&1 || { echo "Command 'vagrant' required but it's not installed.  Aborting." >&2; exit 1; }

. config.sh

echo "Suspending any running instances ..."
vagrant suspend && true
echo "Destroying current box ..."
vagrant destroy -f || true
echo "Removing box '$BUILD_BOX_NAME' ..."
vagrant box remove -f "$BUILD_BOX_NAME" 2>/dev/null || true
echo "Cleaning .vagrant dir ..."
rm -rf .vagrant/ || true
echo "Cleaning packer_cache ..."
rm -rf packer_cache/ || true
echo "Deleting any box file ..."
rm -f *.box || true
echo "Cleanup scripts dir ..."
rm -f scripts/*.tar.xz || true
echo "Cleanup old logs ..."
rm -f packer.log || true
echo "Cleanup old release info ..."
rm -f release || true
echo "Cleanup old stage 3 hash ..."
rm -f BUILD_STAGE3_FILE_HASH || true
echo "Cleanup sensitive information ..."
rm -f ./vagrant-cloud-* || true
echo "All done. You may now run './build.sh' to build a new box."
