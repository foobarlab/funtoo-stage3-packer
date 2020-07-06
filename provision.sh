#!/bin/bash -e

if [ -z ${BUILD_RUN:-} ]; then
  echo "This script can not be run directly! Aborting."
  exit 1
fi

if [ -z ${SCRIPTS:-} ]; then
  SCRIPTS=.
fi

chmod +x $SCRIPTS/scripts/*.sh

BUILD_STAGE3_PATH="$SCRIPTS/scripts/$BUILD_STAGE3_FILE"

for script in \
  01-partition \
  02-mounts \
  03-stage3 \
  04-prepare_chroot \
  05-portage \
  06-update_world \
  07-fstab \
  08-timezone \
  09-bootloader \
  10-networking \
  11-vagrant-user \
  12-software-config \
  13-cleanup
do
  echo "==============================================================================="
  echo " >>> Running $script.sh"
  echo "==============================================================================="
  "$SCRIPTS/scripts/$script.sh"
  printf "\n\n"
done

echo "All done."
