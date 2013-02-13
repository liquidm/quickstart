stage_uri http://next.zentoo.org/downloads/amd64/base-current.tar.bz2
tree_type snapshot http://next.zentoo.org/downloads/snapshots/portage-current.tar.bz2
mirror http://mirror.zentoo.org rsync://rsync.zentoo.org/zentoo-portage-next

rootpw tux
timezone Europe/Berlin

kernel_sources zentoo-sources
kernel_config_uri https://raw.github.com/zentoo/kernels/next/config-3.7.7-zentoo

lvm_logvol vg 10G usr
lvm_logvol vg 10G var

format /dev/vg/usr xfs
format /dev/vg/var xfs

mountfs /dev/vg/usr xfs /usr noatime
mountfs /dev/vg/var xfs /var noatime

extra_packages lvm2 xfsprogs

rcadd devfs sysinit
rcadd udev sysinit
rcadd lvm boot
rcadd sshd default

set_clock() {
	notify "Setting the system clock"
	spawn "/etc/init.d/ntp stop" || :
	spawn "ntpdate pool.ntp.org" || :
	spawn "hwclock --systohc" || :
}

pre_install() {
	set_clock
}
