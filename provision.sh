#!/bin/bash -e

if [ -z ${SCRIPTS:-} ]; then
  SCRIPTS=.
fi

tarball=stage3-latest.tar.xz
tarball_path=$SCRIPTS/scripts/$tarball
if [ -f "$tarball_path" ]
then
	echo "stage3 found: $tarball_path"
else
	echo "stage3 not found: $tarball_path"
	exit 1
fi

chmod +x $SCRIPTS/scripts/*.sh

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
