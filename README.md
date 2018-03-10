# Funtoo Stage3 - Minimal Vagrant Box

This is a minimal stage3 installation of Funtoo Linux that is possible to package into a Vagrant box file. A VirtualBox version is provided. 

### What's included?

 - Stage3 install from [https://build.funtoo.org/funtoo-current/pure64/generic_64-pure64/stage3-latest.tar.xz](https://build.funtoo.org/funtoo-current/pure64/generic_64-pure64/stage3-latest.tar.xz) using [SystemRescueCD](http://www.system-rescue-cd.org)
 - Architecture: pure64, generic_64
 - 100 GB dynamic sized HDD image
 - Timezone: ```UTC```
 - NAT Networking using DHCP
 - Vagrant user *vagrant* with password *vagrant* (can get superuser via sudo without password), additionally using the default ssh authorized keys provided by Vagrant (see https://github.com/hashicorp/vagrant/tree/master/keys) 
 - Kernel: default included from stage3 tarball (debian-sources)
 - Additionally installed software:
   - *boot-update*
   - *sudo*
   - *nfs-utils*
   - *zerofree*

### Download pre-build images

Get the latest build from Vagrant Cloud: [foobarlab/funtoo-stage3](https://app.vagrantup.com/foobarlab/boxes/funtoo-stage3) (~ 527 MB)

### Build your own using Packer

#### Preparation

 - Install [Vagrant](https://www.vagrantup.com/) and [Packer](https://www.packer.io/)

#### Build fresh Virtualbox

 - Run ```./build.sh```
 
#### Test box file

 - Run ```./test.sh```
