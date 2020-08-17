#!/bin/bash -ue

command -v vagrant >/dev/null 2>&1 || { echo "Command 'vagrant' required but it's not installed.  Aborting." >&2; exit 1; }

. config.sh quiet

echo "---------------------------------------------------------------------------"
echo "  CLEANUP"
echo "---------------------------------------------------------------------------"

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
echo "Cleaning output iso dir ..."
rm -rf output-virtualbox-iso/ || true
echo "Deleting any box file ..."
rm -f *.box || true
echo "Cleanup scripts dir ..."
rm -f scripts/*.tar.xz || true
rm -f scripts/.release_$BUILD_BOX_NAME || true
echo "Cleanup old logs ..."
rm -f *.log || true
echo "Cleanup old release info ..."
rm -f release || true
echo "Drop build version ..."
rm -f build_version || true
echo "Cleanup broken wget downloads ..."
rm -f download || true
echo "All done. You may now run './build.sh' to build a fresh box."
