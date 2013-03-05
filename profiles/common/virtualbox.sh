# this one is really ugly since it uses 'uname -r' for kernel detection and it
# cannot be changed easily without breaking checksums, offsets and all kind of
# nasty voodoo in the installer.
#
# as a result, this function should only be used if the source and target setup
# uses the same kernel release
install_guest_additions() {
	cat <<"EOF" > ${chroot_dir}/tmp/vbox.sh
emerge app-emulation/virtualbox-additions

mount /usr/share/virtualbox/VBoxGuestAdditions.iso /mnt/
/mnt/VBoxLinuxAdditions.run --nox11
umount /mnt

emerge -C app-emulation/virtualbox-additions

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
	install_guest_additions
	compact_with_cleanup
	compact_with_zero_fill

	# do not return with failure
	true
}
