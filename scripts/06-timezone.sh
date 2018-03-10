#!/bin/bash -uex

chroot /mnt/funtoo /bin/bash -uex <<'EOF'
ln -snf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
echo $TIMEZONE > /etc/timezone
EOF
