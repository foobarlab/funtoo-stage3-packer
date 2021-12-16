# Funtoo stage3 box packer

This is a customized minimal stage3 snapshot of Funtoo Linux that is packaged into a Vagrant box file.
Currently only a VirtualBox version is provided.

## Operating system

 - Latest Funtoo 1.4 stage3 tarball from
   [https://build.funtoo.org/1.4-release-std/x86-64bit/intel64-nehalem/](https://build.funtoo.org/1.4-release-std/x86-64bit/intel64-nehalem/)
 - (Optional) Funtoo next stage3 tarball from
   [https://build.funtoo.org/next/x86-64bit/generic_64/](https://build.funtoo.org/next/x86-64bit/generic_64/)
 - Box is bootstrapped using [SystemRescueCD](http://www.system-rescue-cd.org)
 - Architecture: x86-64bit, intel64-nehalem (compatible with most CPUs since 2008)
   respectively generic_64 (Funtoo next)
 - Initial 20 GB dynamic sized HDD image (ext4), can be expanded
 - Timezone: UTC
 - NAT Networking using DHCP (virtio)
 - Vagrant user *vagrant* with password *vagrant* (can get superuser via sudo without password),
   additionally using the default SSH authorized keys provided by Vagrant
   (see https://github.com/hashicorp/vagrant/tree/master/keys) 
 - Debian Linux kernel 5.15
 - (Optional) VirtualBox 6.1 Guest Additions
 - Additionally installed utils:
   - *sudo*
   - *usermode-utilities*, *bridge-utils* and *nfs-utils* for advanced networking
   - *acpid* (enables graceful acpi shutdown for VirtualBox)
   - *zerofree* (fills empty hdd space with zeros)
   - *growfs* (resize disk partitions)
   - *eclean-kernel* (cleanup kernel sources and stale files)

### Download pre-build images

Get the latest build from Vagrant Cloud:
[foobarlab/funtoo-stage3](https://app.vagrantup.com/foobarlab/funtoo-stage3)

## Build your own using Packer

Install [VirtualBox](https://www.virtualbox.org) (extensions not needed),
[Vagrant](https://www.vagrantup.com/) and [Packer](https://www.packer.io/).

The provided scripts make use of various commandline utils:

 - bash
 - wget
 - curl
 - jq
 - nproc
 - b2sum
 - sha256sum
 - git
 - make
 - sed
 - awk
 - grep
 - pv

Type ```make``` for help, build your own box with ```make all```.

## Feedback and bug reports welcome

Please create an issue or submit a pull request.
