#!/bin/bash -uea
# vim: ts=4 sw=4 et

# ---- checks

check_vm() {
  todo "check if running inside vm"
}

check_su() {
  todo "check if we are super-user"
}

# ---- setup

# debug mode?
if [[ -v BUILD_DEBUG ]]; then
  if [[ "$BUILD_DEBUG" == "false" ]]; then
    silent=true
  else
    silent=false
  fi
fi

# check if build root is set, otherwise set current working directory
[[ -v BUILD_ROOT ]] || BUILD_ROOT="${PWD}"
step "build root is '$BUILD_ROOT'"

# TODO abort if run from inside vm, run as root, or from wrong dir (must be inside project root)

# TODO check location: ensure path exists and is a directory
#[[ -d "${BUILD_ROOT}" ]] || error "Not a directory or not existant: '${BUILD_ROOT}'"; exit 1
#echo "OK"

# TODO check location: ensure we are not '.' or '..'

# TODO check location: ensure we are not in '/'

# TODO check location: ensure it is a reasonable named dir with reasonable dir depth

# set dir paths
BUILD_DIR_BIN="${BUILD_ROOT:-.}/bin"
BUILD_DIR_LIB="${BUILD_DIR_BIN}/lib"
BUILD_DIR_ETC="${BUILD_ROOT:-.}/etc"
BUILD_DIR_BUILD="${BUILD_ROOT:-.}/build"
BUILD_DIR_PACKER="${BUILD_ROOT:-.}/packer"
BUILD_DIR_DISTFILES="${BUILD_ROOT:-.}/distfiles"
BUILD_DIR_DOWNLOAD="${BUILD_ROOT:-.}/downloads"

# bin files
BUILD_BIN_CONFIG="${BUILD_DIR_BIN}/config.sh"
BUILD_LIB_UTILS="${BUILD_DIR_LIB}/utils.sh"

# packer provisioner
BUILD_FILE_PACKER_HCL="${BUILD_DIR_PACKER}/virtualbox.pkr.hcl"
BUILD_FILE_PACKER_LOG="${BUILD_DIR_BUILD}/packer.log"
#BUILD_FILE_PACKER_CHECKSUM="${BUILD_DIR_BUILD}/packer.sha1.checksum"

# config files
BUILD_FILE_DISTFILESLIST="${BUILD_DIR_ETC}/distfiles.list"
BUILD_FILE_VAGRANT_TOKEN="${BUILD_ROOT}/vagrant-cloud-token"

# files created during build
BUILD_FILE_BUILD_NUMBER="${BUILD_DIR_BUILD}/build_number"
BUILD_FILE_BUILD_TIME="${BUILD_DIR_BUILD}/build_time"
BUILD_FILE_BUILD_VERSION="${BUILD_DIR_BUILD}/build_version"
