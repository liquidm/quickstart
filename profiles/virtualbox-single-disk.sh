. profiles/common/base.sh
. profiles/common/virtualbox.sh

bootloader_install_device /dev/sda

part sda 1 fd00 1G
part sda 2 fd00

lvm_volgroup vg /dev/sda2

format /dev/sda1 ext3

mountfs /dev/sda1 ext3 /

net eth0 dhcp

shutdown

post_install() {
	install_guest_additions
	compact_with_cleanup
	compact_with_zero_fill

	# do not return with failure
	true
}
