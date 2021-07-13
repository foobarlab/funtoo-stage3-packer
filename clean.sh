#!/bin/bash -ue

. config.sh quiet

echo "------------------------------------------------------------------------------"
echo "  CLEANUP"
echo "------------------------------------------------------------------------------"
. clean_box.sh
echo "Cleaning sources ..."
echo ">>> Cleaning .vagrant dir ..."
rm -rf .vagrant/ || true
echo ">>> Cleaning packer_cache ..."
rm -rf packer_cache/ || true
echo ">>> Cleaning packer output dir ..."
rm -rf output-virtualbox-iso/ || true
echo ">>> Deleting any box file ..."
rm -f *.box || true
echo ">>> Cleanup scripts dir ..."
rm -f scripts/*.tar.xz || true
rm -f scripts/.release_$BUILD_BOX_NAME || true
echo ">>> Cleanup old logs ..."
rm -f *.log || true
echo ">>> Cleanup old release info ..."
rm -f release || true
echo ">>> Drop build version ..."
rm -f build_version || true
echo ">>> Drop build runtime ..."
rm -f build_time || true
echo ">>> Cleanup broken wget downloads ..."
rm -f download || true
echo ">>> Cleanup checksum files ..."
rm -f *.checksum || true
echo
echo "All done. You may now run './build.sh' to build a fresh box."
