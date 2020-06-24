#!/bin/bash -uex

if [ -z ${BUILD_RUN:-} ]; then
  echo "This script can not be run directly! Aborting."
  exit 1
fi

if [ -z ${BUILD_CUSTOM_KERNEL:-} ]; then
    echo "BUILD_CUSTOM_KERNEL was not set. Skipping ..."
    exit 0
else
    if [ "$BUILD_CUSTOM_KERNEL" = false ]; then
        echo "BUILD_CUSTOM_KERNEL set to FALSE. Skipping ..."
        exit 0
    fi  
fi

cp ${SCRIPTS}/scripts/kernel.config /mnt/funtoo/usr/src

chroot /mnt/funtoo /bin/bash -uex <<'EOF'
emerge -vt sys-kernel/genkernel
mv /etc/genkernel.conf /etc/genkernel.conf.dist
EOF

cat <<'DATA' | tee -a /mnt/funtoo/etc/genkernel.conf
INSTALL="yes"
OLDCONFIG="yes"
MENUCONFIG="no"
CLEAN="yes"
MRPROPER="no"
MOUNTBOOT="yes"
SYMLINK="no"
SAVE_CONFIG="yes"
USECOLOR="yes"
CLEAR_CACHE_DIR="yes"
POSTCLEAR="1"
#MAKEOPTS=""    # determined by Vagrantfile
LVM="no"
LUKS="no"
GPG="no"
DMRAID="no"
SSH="no"
BUSYBOX="no"
MDADM="no"
MULTIPATH="no"
ISCSI="no"
UNIONFS="no"
BTRFS="no"
FIRMWARE="yes"  # include cpu microcode firmware
FIRMWARE_SRC="/lib/firmware"
DISKLABEL="yes"
BOOTLOADER=""   # grub not needed, we will use ego boot update command
TMPDIR="/var/tmp/genkernel"
BOOTDIR="/boot"
GK_SHARE="${GK_SHARE:-/usr/share/genkernel}"
CACHE_DIR="/usr/share/genkernel"
DISTDIR="${CACHE_DIR}/src"
LOGFILE="/var/log/genkernel.log"
LOGLEVEL=2
DEFAULT_KERNEL_SOURCE="/usr/src/linux"
DEFAULT_KERNEL_CONFIG="/usr/src/kernel.config"
REAL_ROOT="/dev/sda4"
#CMD_CALLBACK="emerge --quiet @module-rebuild"
DATA

chroot /mnt/funtoo /bin/bash -uex <<'EOF'
emerge -vt sys-kernel/linux-firmware sys-firmware/intel-microcode sys-apps/iucode_tool sys-kernel/debian-sources-lts

# select newer kernel if any:
eselect kernel set 2 > /dev/null 2>&1 || eselect kernel set 1

cd /usr/src/linux
make mrproper

# apply 'make olddefconfig' on 'kernel.config' in case kernel config is outdated
cp /usr/src/kernel.config /usr/src/kernel.config.old
mv -f /usr/src/kernel.config /usr/src/linux/.config
make olddefconfig
mv -f /usr/src/linux/.config /usr/src/kernel.config

genkernel --kernel-config=/usr/src/kernel.config --install initramfs all
EOF
