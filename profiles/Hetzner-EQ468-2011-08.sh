# Hetzner EQ4/6/8 profile with Software RAID
# see http://www.hetzner.de/hosting/produktmatrix/rootserver-produktmatrix-eq

stage_uri http://www.zentoo.org/downloads/amd64/stage4-current.tar.bz2
tree_type git-snapshot http://www.zentoo.org/downloads/snapshots/portage-current.tar.bz2 11.0

rootpw icanhazpower
timezone Europe/Berlin

kernel_sources vserver-sources
kernel_config_uri https://raw.github.com/hollow/zentoo-quickstart/master/profiles/Hetzner-EQ468-2011-08.kconfig

bootloader grub
bootloader_install_device /dev/sda1
bootloader_install_device /dev/sdb1

part sda 1 fd 1GB
part sda 2 fd +

part sdb 1 fd 1GB
part sdb 2 fd +

mdraid md1 --metadata=0.90 --level=1 --raid-devices=2 /dev/sda1 /dev/sdb1
mdraid md2 --metadata=0.90 --level=1 --raid-devices=2 /dev/sda2 /dev/sdb2

lvm_volgroup vg /dev/md2
lvm_logvol vg 10G usr
lvm_logvol vg 10G var

format /dev/md1 ext3
format /dev/vg/usr xfs
format /dev/vg/var xfs

mountfs /dev/md1 ext3 /
mountfs /dev/vg/usr xfs /usr noatime
mountfs /dev/vg/var xfs /var noatime

extra_packages mdadm lvm2 xfsprogs

rcadd lvm boot
rcadd sshd default

net eth0 current

reboot

pre_install() {
	notify "Setting the system clock"
	spawn "/etc/init.d/ntp stop"
	spawn "ntpdate pool.ntp.org"
	spawn "hwclock --systohc"
}
