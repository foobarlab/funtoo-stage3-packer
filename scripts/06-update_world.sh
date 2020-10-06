#!/bin/bash -uex

if [ -z ${BUILD_RUN:-} ]; then
  echo "This script can not be run directly! Aborting."
  exit 1
fi

# update world, but skip kernel
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
# ensure we use a valid gcc version (see also FL-6143)
gcc-config -l || gcc-config 1
# re-sync
ego sync
emerge -vt --update --newuse --deep --with-bdeps=y @world --exclude="sys-kernel/debian-sources-lts"
EOF
