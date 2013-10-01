# this one is really ugly since it uses 'uname -r' for kernel detection and it
# cannot be changed easily without breaking checksums, offsets and all kind of
# nasty voodoo in the installer.
#
# as a result, this function should only be used if the source and target setup
# uses the same kernel release
install_guest_additions() {
	cat <<"EOF" > ${chroot_dir}/tmp/vbox.sh
set -e

emerge sys-kernel/gentoo-sources app-emulation/virtualbox-additions

pushd /usr/src/linux
cp /boot/config-* .config
make modules_prepare
popd

mount /usr/share/virtualbox/VBoxGuestAdditions.iso /mnt/
/mnt/VBoxLinuxAdditions.run --nox11
umount /mnt

rm -f /tmp/vbox.sh
EOF

	spawn_chroot "bash /tmp/vbox.sh"

	cat <<"EOF" > ${chroot_dir}/etc/modules-load.d/virtualbox.conf
vboxguest
vboxsf
EOF
}

compact_with_cleanup() {
	spawn_chroot "rm -rf /var/cache/genkernel"
	spawn_chroot "rm -rf /usr/portage/distfiles/* /usr/portage/packages/*"
}

post_install() {
	install_guest_additions
	compact_with_cleanup

	# do not return with failure
	true
}
