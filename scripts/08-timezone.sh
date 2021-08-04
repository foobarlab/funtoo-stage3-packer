#!/bin/bash -uex

if [ -z ${BUILD_RUN:-} ]; then
  echo "This script can not be run directly! Aborting."
  exit 1
fi

chroot /mnt/funtoo /bin/bash -uex <<'EOF'
ln -snf /usr/share/zoneinfo/$BUILD_TIMEZONE /etc/localtime
echo $BUILD_TIMEZONE > /etc/timezone
EOF
