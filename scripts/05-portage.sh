#!/bin/bash -uex

if [ -z ${BUILD_RUN:-} ]; then
  echo "This script can not be run directly! Aborting."
  exit 1
fi

cat <<'DATA' | tee -a /mnt/funtoo/etc/portage/make.conf
ACCEPT_LICENSE="-* @FREE @BINARY-REDISTRIBUTABLE"
DATA

if [ -z ${BUILD_CUSTOM_KERNEL:-} ]; then
    echo "BUILD_CUSTOM_KERNEL set to FALSE. Skipping portage preparation ..."
else
    if [ "$BUILD_CUSTOM_KERNEL" = false ]; then
        echo "BUILD_CUSTOM_KERNEL set to FALSE. Skipping portage preparation ..."
    else
        mkdir -p /mnt/funtoo/etc/portage/package.use
cat <<'DATA' | tee -a /mnt/funtoo/etc/portage/package.use/vbox-kernel
sys-kernel/genkernel -cryptsetup
sys-kernel/debian-sources-lts -binary -custom-cflags
sys-firmware/intel-microcode initramfs
sys-kernel/linux-firmware initramfs
DATA
        mkdir -p /mnt/funtoo/etc/portage/package.license
cat <<'DATA' | tee -a /mnt/funtoo/etc/portage/package.license/vbox-kernel
sys-kernel/linux-firmware linux-fw-redistributable
DATA
    fi
fi
chroot /mnt/funtoo /bin/bash -uex <<'EOF'
ego sync
EOF
