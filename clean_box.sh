#!/bin/bash -ue

echo "Removing Vagrant box ..."

. config.sh quiet

require_commands vagrant

echo ">>> Suspending any running instances named '$BUILD_BOX_NAME' ..."
vagrant suspend "$BUILD_BOX_NAME" 2>/dev/null || true
echo ">>> Destroying current box ..."
vagrant destroy -f || true
echo ">>> Removing box '$BUILD_BOX_NAME' ..."
vagrant box remove -f "$BUILD_BOX_NAME" 2>/dev/null || true
