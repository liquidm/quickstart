stage_uri http://www.zentoo.org/downloads/amd64/base-current.tar.bz2
tree_type snapshot http://www.zentoo.org/downloads/snapshots/portage-current.tar.bz2
mirror http://mirror.zentoo.org rsync://rsync.zentoo.org/zentoo-portage

rootpw tux
timezone Europe/Berlin

kernel_image sys-kernel/zentoo-image

lvm_logvol vg 10G usr
lvm_logvol vg 10G var

format /dev/vg/usr xfs
format /dev/vg/var xfs

mountfs /dev/vg/usr xfs /usr noatime
mountfs /dev/vg/var xfs /var noatime

extra_packages lvm2 xfsprogs zentoo-image

set_clock() {
	notify "Setting the system clock"
	spawn "/etc/init.d/ntp stop" || :
	spawn "ntpdate pool.ntp.org" || :
	spawn "hwclock -w -u" || :
}

pre_install() {
	set_clock
}
