#!/bin/bash -uex

if [ -z ${BUILD_RUN:-} ]; then
  echo "This script can not be run directly! Aborting."
  exit 1
fi

# add custom overlay?
if [ "$BUILD_CUSTOM_OVERLAY" = true ]; then
	chroot /mnt/funtoo /bin/bash -uex <<'EOF'
cd /var/git
mkdir -p overlay
cd overlay
git clone --depth 1 -b $BUILD_CUSTOM_OVERLAY_BRANCH "$BUILD_CUSTOM_OVERLAY_URL" ./$BUILD_CUSTOM_OVERLAY_NAME
cd ./$BUILD_CUSTOM_OVERLAY_NAME
git config pull.ff only       # strategy: fast forward only
chown -R portage.portage /var/git/overlay
EOF

	chroot /mnt/funtoo /bin/bash -uex <<'EOF'
cat > /etc/portage/repos.conf/$BUILD_CUSTOM_OVERLAY_NAME <<'DATA'
[DEFAULT]
main-repo = core-kit

[BUILD_CUSTOM_OVERLAY_NAME]
location = /var/git/overlay/BUILD_CUSTOM_OVERLAY_NAME
auto-sync = no
priority = 10
DATA
sed -i 's/BUILD_CUSTOM_OVERLAY_NAME/'"$BUILD_CUSTOM_OVERLAY_NAME"'/g' /etc/portage/repos.conf/$BUILD_CUSTOM_OVERLAY_NAME
EOF
fi

# update portage/ego, and update world, but skip kernel
chroot /mnt/funtoo /bin/bash -uex <<'EOF'
ego sync
emerge -s app-admin/ego
emerge -vt app-admin/ego
emerge -s sys-apps/portage
emerge -vt sys-apps/portage
env-update
source /etc/profile
etc-update --preen
etc-update --automode -5
# ensure we use a valid gcc version (see FL-6143)
gcc-config -l || gcc-config 1
# update world, keep existing kernel
ego sync
# TEMP FIX START: repair Manifest file (FL-8426)
ebuild /var/git/meta-repo/kits/core-kit/sys-libs/binutils-libs/binutils-libs-2.36.1-r1.ebuild digest
chown portage.portage /var/git/meta-repo/kits/core-kit/sys-libs/binutils-libs/Manifest
# TEMP FIX END: repair Manifest file (FL-8426)
emerge -vt --update --newuse --deep --with-bdeps=y @world --exclude="sys-kernel/debian-sources-lts" --exclude="sys-kernel/debian-sources"
EOF

# rebuild system?
if [ "$BUILD_REBUILD_SYSTEM" = true ]; then
chroot /mnt/funtoo /bin/bash -uex <<'EOF'
env-update
source /etc/profile
emerge -vt --update --newuse --deep --with-bdeps=y @world
emerge --depclean
emerge -vt @preserved-rebuild
emerge -vte --usepkg=n @system
env-update
source /etc/profile
emerge -vte --usepkg=n @world
emerge -vt @preserved-rebuild
EOF
fi
