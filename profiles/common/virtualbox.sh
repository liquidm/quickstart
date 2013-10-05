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

vagrant_post_install() {
	# setup user
	spawn_chroot "useradd -m -d /home/vagrant -g users -G wheel,portage,cron vagrant" || die "failed to create vagrant user"
	spawn_chroot "echo vagrant:vagrant | chpasswd" || die "failed to set vagrant password"
	spawn_chroot "curl -s -k -L https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub > /home/vagrant/.ssh/authorized_keys" || die "failed to download vagrant public key"

	# sudo configuration
	cat <<EOF > ${chroot_dir}/etc/sudoers
Defaults env_keep="EDITOR SSH_AUTH_SOCK"
root    ALL = (ALL) ALL
%wheel  ALL = (ALL) NOPASSWD: ALL
EOF
}

compact_with_cleanup() {
	spawn_chroot "rm -rf /var/cache/genkernel" || die "failed to remove caches"
	spawn_chroot "rm -rf /usr/portage/distfiles/* /usr/portage/packages/*" || die "failed to remove distfiles"
}

post_install() {
	install_guest_additions
	vagrant_post_install
	compact_with_cleanup

	# do not return with failure
	true
}
