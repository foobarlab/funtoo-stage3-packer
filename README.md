# Funtoo Stage3 Vagrant box

This is a minimal stage3 snapshot of Funtoo Linux that is packaged into a Vagrant box file. Currently only a VirtualBox version is provided.
This box serves as initial base box for the [Funtoo Core Vagrant box](https://github.com/foobarlab/funtoo-core-packer).

### What's included?

 - Latest stage3 tarball from [https://build.funtoo.org/funtoo-current/pure64/generic_64-pure64/stage3-latest.tar.xz](https://build.funtoo.org/funtoo-current/pure64/generic_64-pure64/stage3-latest.tar.xz) using [SystemRescueCD](http://www.system-rescue-cd.org)
 - Architecture: pure64, generic_64
 - 100 GB dynamic sized HDD image (ext4)
 - Timezone: ```UTC```
 - NAT Networking using DHCP
 - Vagrant user *vagrant* with password *vagrant* (can get superuser via sudo without password), additionally using the default ssh authorized keys provided by Vagrant (see https://github.com/hashicorp/vagrant/tree/master/keys) 
 - No Virtualbox guest additions installed, no shared folders
 - Kernel: default included from stage3 tarball (debian-sources)
 - Additionally installed software:
   - *boot-update* (implies *grub*)
   - *sudo*
   - *nfs-utils*
   - *zerofree*

### Download pre-build images

Get the latest build from Vagrant Cloud: [foobarlab/funtoo-stage3](https://app.vagrantup.com/foobarlab/boxes/funtoo-stage3)

### Build your own using Packer

#### Preparation

 - Install [Vagrant](https://www.vagrantup.com/) and [Packer](https://www.packer.io/)

#### Build a fresh Virtualbox box

 - Run ```./build.sh```
 
#### Quick test the box file

 - Run ```./test.sh```

#### Upload the box to Vagrant Cloud (experimental)

 - Run ```./upload.sh```

### Regular use cases

#### Initialize a fresh box (initial state, any modifications are lost)

 - Run ```./init.sh```

#### Power on the box (keeping previous state) 

 - Run ```./startup.sh```
 