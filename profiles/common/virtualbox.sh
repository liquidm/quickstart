prepare_virtualbox_guest() {
	cat <<"EOF" > ${chroot_dir}/tmp/vbox.sh
set -e

emerge sys-kernel/gentoo-sources app-emulation/virtualbox-additions

pushd /usr/src/linux
cp /boot/config-* .config
make modules_prepare
popd

rm -f /tmp/vbox.sh
EOF

	spawn_chroot "bash /tmp/vbox.sh"
}

compact_with_cleanup() {
	spawn_chroot "rm -rf /usr/src/linux-* /var/cache/genkernel"
	spawn_chroot "rm -rf /usr/portage/distfiles/* /usr/portage/packages/*"
}

compact_with_zero_fill() {
	for part in / /usr /var; do
		spawn_chroot "cat /dev/zero > ${part}/zero.fill; sync; rm -f ${part}/zero.fill; sync"
	done
}

post_install() {
	prepare_virtualbox_guest
	compact_with_cleanup
	compact_with_zero_fill

	# do not return with failure
	true
}
