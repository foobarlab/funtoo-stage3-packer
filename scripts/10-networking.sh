#!/bin/bash -uex
# vim: ts=2 sw=2 et

if [ -z ${BUILD_RUN:-} ]; then
  echo "This script can not be run directly! Aborting."
  exit 1
fi

chroot /mnt/funtoo /bin/bash -uex <<'EOF'
rc-update add dhcpcd default
EOF
