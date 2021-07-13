#!/bin/bash -ue

vboxmanage=VBoxManage
command -v $vboxmanage >/dev/null 2>&1 || vboxmanage=vboxmanage   # try alternative

. config.sh quiet

require_commands vagrant $vboxmanage

echo "------------------------------------------------------------------------------"
echo "  ENVIRONMENT CLEANUP"
echo "------------------------------------------------------------------------------"
echo "Housekeeping Vagrant environment ..."
echo ">>> Prune invalid Vagrant entries ..."
vagrant global-status --prune >/dev/null
echo ">>> Delete temporary Vagrant files ..."
rm -rf ~/.vagrant.d/tmp/*

echo "Housekeeping VirtualBox environment ..."
echo ">>> Forcibly shutdown any running VirtualBox VM named '$BUILD_BOX_NAME' ..."
vbox_running_id=$( $vboxmanage list runningvms | grep "\"$BUILD_BOX_NAME\"" | sed -r 's/.*\{(.*)\}/\1/' )
$vboxmanage controlvm "$vbox_running_id" acpipowerbutton >/dev/null 2>&1 || true
$vboxmanage controlvm "$vbox_running_id" poweroff >/dev/null 2>&1 || true

echo ">>> Searching for VirtualBox named '$BUILD_BOX_NAME' ..."
vbox_machine_id=$( $vboxmanage list vms | grep $BUILD_BOX_NAME | grep -Eo '{[0-9a-f\-]+}' | sed -n 's/[{}]//p' || echo )
if [[ -z "$vbox_machine_id" || "$vbox_machine_id" = "" ]]; then
  echo "No machine named '$BUILD_BOX_NAME' found."
else
  echo "Found machine UUID for '$BUILD_BOX_NAME': { $vbox_machine_id }"
  echo ">>> Deleting machine ..."
  $vboxmanage unregistervm --delete $vbox_machine_id >/dev/null 2>&1 || true
fi
# TODO check if this is needed:
#echo ">>> Searching for VirtualBox HDDS named '${BUILD_BOX_NAME}.vdi' ..."
#vbox_hdd_found=$( $vboxmanage list hdds | grep "${BUILD_BOX_NAME}.vdi" || echo )
#if [[ -z "$vbox_hdd_found" || "$vbox_hdd_found" = "" ]]; then
#  echo "No HDD named '${BUILD_BOX_NAME}.vdi' found."
#else
#  echo "HDD found."
#  echo "TODO: Searching for HDD UUID ..."
#  # DEBUG:
#  #$vboxmanage list hdds
#  #$vboxmanage list hdds | grep -o "^UUID" | wc -l
#  #$vboxmanage list hdds | grep -on "^UUID.*"
#  #$vboxmanage list hdds | grep -on "^State:.*"
#  #$vboxmanage list hdds | grep -on "^Location:.*"
#  echo "TODO: Removing HDD from Media Manager ..."
#  #$vboxmanage closemedium disk $vbox_hdd_id --delete
#fi
echo ">>> Delete all inaccessible VMs named '$BUILD_BOX_NAME' ..."
vbox_inaccessible_id=$( $vboxmanage list vms | grep "<inaccessible>" | grep "$BUILD_BOX_NAME" | sed -r 's/.*\{(.*)\}/\1/' )
if [[ -z "$vbox_inaccessible_id" || "$vbox_inaccessible_id" = "" ]]; then
  echo "No inaccessible machine named '$BUILD_BOX_NAME' found."
else
  echo "Found inaccessible machine UUID for '$BUILD_BOX_NAME': { vbox_inaccessible_id }"
  $vboxmanage unregistervm --delete "$vbox_inaccessible_id" >/dev/null 2>&1 || true
fi
echo ">>> Force remove of appliance from VirtualBox machine folder ..."
vboxmachinefolder=$( $vboxmanage list systemproperties | grep "Default machine folder" | cut -d ':' -f2 | sed -e 's/^\s*//g' )
rm -rf "$vboxmachinefolder/$BUILD_BOX_NAME/" || true

echo "Housekeeping sources ..."

echo ">>> Drop build number ..."
rm -f build_number || true

# basic cleanup
echo
. clean.sh
