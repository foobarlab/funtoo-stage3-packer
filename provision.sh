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
  05-fstab \
  06-timezone \
  07-boot-update \
  08-networking \
  09-vagrant-user \
  10-cleanup
do
  echo "**** Running $script ******"
  "$SCRIPTS/scripts/$script.sh"
done

echo "All done."
