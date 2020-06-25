#!/bin/bash -uex

if [ -z ${BUILD_RUN:-} ]; then
  echo "This script can not be run directly! Aborting."
  exit 1
fi

chroot /mnt/funtoo /bin/bash -uex <<'EOF'
# initial sync
ego sync
# upgrade to latest ego
emerge -s app-admin/ego
emerge -vt app-admin/ego
env-update
source /etc/profile
etc-update --preen
etc-update --automode -5
emerge --depclean
# ensure we use a valid gcc version (see also FL-6143)
gcc-config -l || gcc-config 1
EOF

chroot /mnt/funtoo /bin/bash -uex <<'EOF'
emerge --update --newuse --deep --with-bdeps=y @world
EOF
