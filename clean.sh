#!/bin/bash -ue
echo "Suspending any running instances ..."
vagrant suspend && true
echo "Destroying current box ..."
vagrant destroy -f || true
echo "Cleaning .ssh dir ..."
rm -rf .ssh/ || true
echo "Cleaning .vagrant dir ..."
rm -rf .vagrant/ || true
echo "Cleaning packer_cache ..."
rm -rf packer_cache/ || true
echo "Removing hash file ..."
rm -f *.tar.xz.hash.txt || true
echo "Deleting any box file ..."
rm -f *.box || true
echo "All done. You may now run './build.sh' to build a new box."
