About
=====
As long as you can reach rescue mode, you can make any bare metal install your
linux distribution of choice.

This version of quickstart actually works with Ubuntu.

Example profile.sh (`./quickstart -v -d profile.sh`)
====================================================
```
net eth0 current

part sda 1 fd00
part sdb 1 fd00

mdraid md1 --level=1 --raid-devices=2 /dev/sda1 /dev/sdb1

format /dev/md1 ext4

mountfs /dev/md1 ext4 /

ssh_authorized_key "root pub key for first login"

#legacy boot (either)
post_install(){
  spawn_chroot "/usr/sbin/grub-install /dev/sda"
  spawn_chroot "/usr/sbin/grub-install /dev/sdb"
  spawn_chroot "update-grub"
}

#efi-boot (or)
post_install(){
  chroot /mnt/quickstart_root apt-get -y install grub-efi-amd64
  mkfs.msdos /dev/sda128
  mkdir /mnt/quickstart_root/efi
  mount /dev/sda128 /mnt/quickstart_root/efi
  echo -e '\n/dev/sda128\t/efi\tvfat\tdefaults\t0 2' >> /mnt/quickstart_root/etc/fstab
  mv /mnt/quickstart_root/boot/grub /mnt/quickstart_root/efi/
  ln -s ../efi/grub /mnt/quickstart_root/boot/
  spawn_chroot "grub-install --efi-directory=/efi --boot-directory=/efi"
  spawn_chroot "update-grub"
  umount /mnt/quickstart_root/efi
}

```

Origin
======

Back in October 2006, I got bored one weekend and decided that the Gentoo Linux
Installer (GLI, or "the installer") sucked and was no longer on track to
achieve its original goal of acting as an installer for automated deployments
of Gentoo to multiple machines. I decided that I would address one of the chief
complaints about GLI (that python was too bloated to fit in a netboot image) by
writing my replacement in POSIX sh, so that it could run with busybox ash. Thus,
Quickstart was born.

The first version had a very cumbersome config syntax (defining vars in a
"profile" which was sourced by install.sh). Newer versions use a config syntax
that's modeled on Kickstart's config syntax. Under the hood, it's still the same
arcane variables, but now they're hidden by pretty "wrapper" functions that set
the variables appropriately based on the options passed to them. A list of all
configurable options is available in the file doc/config.txt. You can also find
an example profile in the same directory.

Features

    * partitioning from a blank disk (drive is wiped)
    * specify partition sizes in MB, GB, % of remaining, or + (all remaining)
    * creation of md raid arrays
    * ability to format partitions as ext2, ext3, swap, reiserfs, xfs, or jfs
    * specify local filesystems to be mounted during the install
    * specify network shares to be mounted during the install
    * choose your root password (plain-text or pre-encrypted)
    * specify URI for stage 3 tarball (file, http, https, ftp, or rsync)
    * specify method for getting a portage tree (sync, webrsync, or snapshot)
    * specify the directory that is used for the chroot
    * specify extra packages to be emerged after the base system
    * specify extra options passed to genkernel
    * specify URI for pre-made kernel config
    * choose which kernel sources package to use to build your kernel
    * choose your timezone
    * choose which services to add to which runlevels
    * choose which services to remove from which runlevels
    * specify basic networking configuration
    * run custom code using pre-/post-install step hooks in the config file (it's just a sh file)
    * many more things that I just can't think of


Standard license, copyright, and, disclaimer blurb
===================================================

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, version 2 only.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

This program ("Quickstart") is copyright 2006-2008 Andrew Gaffney.
