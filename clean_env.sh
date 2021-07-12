#!/bin/bash -ue

# DEBUG:
#set -x

vboxmachinefolder="~/.VirtualBox/Machines"

vboxmanage=VBoxManage
command -v $vboxmanage >/dev/null 2>&1 || vboxmanage=vboxmanage   # try alternative

. config.sh quiet

require_commands vagrant $vboxmanage

echo "------------------------------------------------------------------------------"
echo "  ENVIRONMENT CLEANUP (Vagrant and VirtualBox)"
echo "------------------------------------------------------------------------------"
echo "Housekeeping Vagrant environment ..."

# TODO some more system cleanup:
# => suspend all VMs as seen by the current user
# => delete temporary files as seen by the current user
echo ">>> Suspend any running Vagrant VMs ..."
vagrant global-status | awk '/running/{print $1}' | xargs -r -d '\n' -n 1 -- vagrant suspend
echo ">>> Prune invalid Vagrant entries ..."
vagrant global-status --prune >/dev/null
echo ">>> Delete temporary Vagrant files ..."
rm -rf ~/.vagrant.d/tmp/*

. clean_box.sh

echo
echo "Housekeeping VirtualBox environment ..."

echo ">>> Forcibly shutdown any running VirtualBox VMs ..."
$vboxmanage list runningvms | sed -r 's/.*\{(.*)\}/\1/' | awk '{print "$vboxmanage controlvm "$1" acpipowerbutton\0"}' | xargs -0 >/dev/null
$vboxmanage list runningvms | sed -r 's/.*\{(.*)\}/\1/' | awk '{print "$vboxmanage controlvm "$1" poweroff\0"}' | xargs -0 >/dev/null

echo ">>> Searching for VirtualBox '$BUILD_BOX_NAME' ..."
vbox_machine_id=$( $vboxmanage list vms | grep $BUILD_BOX_NAME | grep -Eo '{[0-9a-f\-]+}' | sed -n 's/[{}]//p' )
if [[ -z "$vbox_machine_id" || "$vbox_machine_id" = "" ]]; then
  echo "DEBUG: no machine '$BUILD_BOX_NAME' found."
else
  echo "DEBUG: found machine id for '$BUILD_BOX_NAME': { $vbox_machine_id }"
  
  # DEBUG: show SATA related info:
  #vboxmanage showvminfo $vbox_machine_id --machinereadable | grep "SATA"
  
  vbox_hdd_id=$( $vboxmanage showvminfo $vbox_machine_id --machinereadable | grep "SATA Controller-ImageUUID-0-0" | cut -d '=' -f2 |  tr -d '"' )
  
  if [[ -z "$vbox_hdd_id" || "$vbox_hdd_id" = "" ]]; then
    echo "DEBUG: no hdd found."
  else
    echo ">>> Force remove of any related VirtualBox hdd ..."
  
    echo "DEBUG: found hdd id for '$BUILD_BOX_NAME': { $vbox_hdd_id }"

    # TODO force shutdown, unlock/release hdd ...

    #echo $vbox_hdd_id | awk '{print "$vboxmanage closemedium disk "$1" --delete\0"}' | xargs -0 >/dev/null
  
    # FIXME detach:
    #$vboxmanage storageattach $BUILD_BOX_NAME --storagectl "SATA Controller" --port 0 --device 0 --medium none # >/dev/null 2>&1 || true
    #$vboxmanage storageattach $vbox_machine_id --storagectl "SATA Controller-0-0" --port 0 --device 0 --medium none # >/dev/null 2>&1 || true
    
    #vboxmanage storageattach funtoo-stage3 --storagectl "SATA Controller" --type hdd --port 0 --device 0 --medium none
    
    # FIXME:
    #$vboxmanage storageattach $vbox_machine_id --storagectl "SATA Controller-0-0" --type hdd --port 0 --device 0 --medium none >/dev/null 2>&1 || true
    
    #echo $vbox_hdd_id | awk '{print "$vboxmanage closemedium disk "$1" --delete\0"}'
    echo $vbox_hdd_id | awk '{print "$vboxmanage closemedium disk "$1" --delete\0"}' | xargs -0 >/dev/null

  fi

  # TODO delete machine

fi

echo ">>> Delete all inaccessible VMs ..."
$vboxmanage list vms | grep "<inaccessible>" | sed -r 's/.*\{(.*)\}/\1/' | awk '{print "$vboxmanage unregistervm --delete "$1"\0"}' | xargs -0 >/dev/null
echo ">>> Force remove of appliance from VirtualBox machine folder ..."
# FIXME assumed path ~/.VirtualBox/Machines/ might be incorrect, better get this from VirtualBox config somehow
rm -rf $vboxmachinefolder/$BUILD_BOX_NAME/ || true

echo
echo "Housekeeping sources ..."

echo ">>> Drop build number ..."
rm -f build_number || true

# basic cleanup
echo
. clean.sh
