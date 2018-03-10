#!/bin/bash -uex

chroot /mnt/funtoo /bin/bash -uex <<'EOF'
rc-update add dhcpcd default
EOF
