#!/bin/bash -uex

tarball=stage3-latest.tar.xz
tarball_path=$SCRIPTS/scripts/$tarball

cd /mnt/funtoo
if [ -f "$tarball_path" ]
then
	cp $tarball_path /mnt/funtoo
else
	wget http://build.funtoo.org/funtoo-current/x86-64bit/generic_64/$tarball
	cp $tarball /mnt/funtoo
fi

cd /mnt/funtoo
tar xpf $tarball
rm -f $tarball
ls -l
