stage_uri http://www.zentoo.org/downloads/amd64/zentoo-host-amd64-current.tar.bz2
tree_type snapshot http://www.zentoo.org/downloads/snapshots/portage-current.tar.bz2
mirror http://mirror.zentoo.org

rootpw tux
timezone Europe/Berlin

kernel_sources vserver-sources
kernel_config_uri https://raw.github.com/zentoo/quickstart/master/profiles/3.2.5-vs2.3.2.6-generic.kconfig

lvm_logvol vg 10G usr
lvm_logvol vg 10G var

format /dev/vg/usr xfs
format /dev/vg/var xfs

mountfs /dev/vg/usr xfs /usr noatime
mountfs /dev/vg/var xfs /var noatime

extra_packages lvm2 xfsprogs

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
