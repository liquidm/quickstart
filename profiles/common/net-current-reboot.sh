net eth0 current

reboot

pre_install() {
	notify "Setting the system clock"
	spawn "/etc/init.d/ntp stop"
	spawn "ntpdate pool.ntp.org"
	spawn "hwclock --systohc"
}
