# Funtoo Stage3 Vagrant box

This is a minimal stage3 snapshot of Funtoo Linux that is packaged into a Vagrant box file. Currently only a VirtualBox version is provided.

### What's included?

 - Latest Funtoo 1.4 stage3 tarball from [https://build.funtoo.org/1.4-release-std/x86-64bit/intel64-nehalem/stage3-latest.tar.xz](https://build.funtoo.org/1.4-release-std/x86-64bit/intel64-nehalem/stage3-latest.tar.xz) using [SystemRescueCD](http://www.system-rescue-cd.org)
 - Architecture: x86-64bit, intel64-nehalem (compatible with most CPUs since 2008)
 - Initial 25 GB dynamic sized HDD image (ext4), can be expanded
 - Timezone: ```UTC```
 - NAT Networking using DHCP (virtio)
 - Vagrant user *vagrant* with password *vagrant* (can get superuser via sudo without password), additionally using the default SSH authorized keys provided by Vagrant (see https://github.com/hashicorp/vagrant/tree/master/keys) 
 - Kernel 5.10 (debian-sources)
 - (Optional, enabled by default) VirtualBox 6.1 Guest Additions
 - Additionally installed software:
   - *sudo*
   - *usermode-utilities*, *bridge-utils* and *nfs-utils* for advanced networking
   - *acpid* (enables graceful acpi shutdown for VirtualBox)
   - *zerofree* (fills empty hdd space with zeros)
   - *parted* (manage file system partitions)
   - *eclean-kernel* (cleanup kernel sources and stale files)

### Download pre-build images

Get the latest build from Vagrant Cloud: [foobarlab/funtoo-stage3](https://app.vagrantup.com/foobarlab/boxes/funtoo-stage3)

### Build your own using Packer

#### Preparation

 - Install [Vagrant](https://www.vagrantup.com/) and [Packer](https://www.packer.io/)

#### Build a fresh VirtualBox box

 - Run ```./build.sh```
 
#### Quick test the box file

 - Run ```./test.sh```

#### Upload the box to Vagrant Cloud (account required)

 - Run ```./upload.sh```

### Regular use cases

#### Initialize a fresh box (initial state, any modifications are lost)

 - Run ```./init.sh```

#### Power on the box (keeping previous state)

 - Run ```./startup.sh```

### Special use cases

#### Show current build config

 - Run ```./config.sh```

#### Cleanup build environment (poweroff and remove any related Vagrant and VirtualBox machines)

 - Run ```./clean_env.sh```

#### Cleanup temporary build Vagrant box

 - Run ```./clean_box.sh```

#### Cleanup build environment

 - Run ```./clean.sh```

#### Generate Vagrant Cloud API Token

 - Run ```./vagrant_cloud_token.sh```

#### Keep only a maximum number of boxes in Vagrant Cloud (experimental)

 - Run ```./clean_cloud.sh```

## Feedback and bug reports welcome

Please create an issue or submit a pull request.
