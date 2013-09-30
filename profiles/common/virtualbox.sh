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
	compact_with_cleanup
	compact_with_zero_fill

	# do not return with failure
	true
}
