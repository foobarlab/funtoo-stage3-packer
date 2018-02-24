# Funtoo stage3 Vagrant box

This is a minimal stage3 installation of Funtoo Linux that is packaged into a Vagrant box file. Currently only a VirtualBox version is provided.

### Purpose

This box is intended to serve as a generic startpoint to build a derived base box. The box does not include the VirtualBox guest additions.

### What's included?

 - Latest stage3 tarball from [http://build.funtoo.org/funtoo-current/x86-64bit/generic_64/stage3-latest.tar.xz](http://build.funtoo.org/funtoo-current/x86-64bit/generic_64/stage3-latest.tar.xz) using [SystemRescueCD](http://www.system-rescue-cd.org)
 - Architecture: amd64, generic_64
 - 100 GB dynamic sized HDD image
 - Timezone: ```UTC```
 - NAT Networking using DHCP
 - Vagrant user *vagrant* with password *vagrant* (can get superuser via sudo without password), additionally using the default ssh authorized keys provided by Vagrant (see https://github.com/hashicorp/vagrant/tree/master/keys) 
 - Kernel: default included from stage3 tarball (debian-sources)
 - Additionally installed software:
   - *boot-update* and *grub*
   - *sudo*
   - *nfs-utils*
   - *zerofree*

### Download pre-build images

Get the latest build from Vagrant Cloud: [foobarlab/funtoo-stage3](https://app.vagrantup.com/foobarlab/boxes/funtoo-stage3) (~ 554 MB)

### Build your own using Packer

#### Preparation

 - Install [Vagrant](https://www.vagrantup.com/) and [Packer](https://www.packer.io/)

#### Build fresh Virtualbox

 - Run ```./build.sh```
 
#### Test box file

 - Run ```./test.sh```
