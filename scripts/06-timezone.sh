#!/bin/bash -uex

chroot /mnt/funtoo /bin/bash -uex <<'EOF'
ln -snf /usr/share/zoneinfo/UTC /etc/localtime
echo UTC > /etc/timezone
EOF