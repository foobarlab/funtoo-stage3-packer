#!/bin/bash -uex

if [ -z ${BUILD_RUN:-} ]; then
  echo "This script can not be run directly! Aborting."
  exit 1
fi

if [ -z ${BUILD_CUSTOM_KERNEL:-} ]; then
    echo "BUILD_CUSTOM_KERNEL not set. Including default kernel and config..."
else
    if [ "$BUILD_CUSTOM_KERNEL" = false ]; then
        echo "BUILD_CUSTOM_KERNEL set to FALSE. Including default kernel and config ..."
    else
        echo "BUILD_CUSTOM_KERNEL set to TRUE. Preventing default kernel from being build ..."
        BUILD_WORLD_EXCLUDES="--exclude sys-kernel/debian-sources-lts"
    fi
fi
chroot /mnt/funtoo /bin/bash -uex -c "emerge --update --newuse --deep --with-bdeps=y @world ${BUILD_WORLD_EXCLUDES:-}"

## workaround: upgrade to latest ego and re-sync
#chroot /mnt/funtoo /bin/bash -uex <<'EOF'
#emerge -s app-admin/ego
#emerge -vt app-admin/ego
#env-update
#source /etc/profile
#etc-update --preen
#etc-update --automode -5
#emerge --depclean
#EOF

## workaround for FL-6143: ensure we use a valid gcc version:
#chroot /mnt/funtoo /bin/bash -uex <<'EOF'
#gcc-config -l || gcc-config 1
#ego sync
#EOF
