stage_uri http://mirror.zenops.net/zentoo/amd64/zentoo-amd64-base.tar.bz2
tree_type snapshot http://mirror.zenops.net/zentoo/snapshots/portage-current.tar.bz2
mirror http://mirror.zenops.net/zentoo rsync://mirror.zenops.net/zentoo-portage

rootpw tux
timezone Europe/Berlin

kernel_image sys-kernel/zentoo-image

extra_packages xfsprogs

set_clock() {
	notify "Setting the system clock"
	spawn "/etc/init.d/ntp stop" || :
	spawn "ntpdate pool.ntp.org" || :
	spawn "hwclock -w -u" || :
}

install_dependencies() {
	spawn "apt-get install -y gdisk" || :
}

pre_install() {
	set_clock
	install_dependencies
}
