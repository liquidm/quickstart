# this one is really ugly since it uses 'uname -r' for kernel detection and it
# cannot be changed easily without breaking checksums, offsets and all kind of
# nasty voodoo in the installer.
#
# to make it work we move a dummy uname script in place and revert it again
# afterwards ... *sigh*
install_guest_additions() {
	cat <<"EOF" > ${chroot_dir}/usr/bin/uname.vbox
#!/bin/bash

case $1 in
	-r)
		echo $(basename $(ls -1d /lib/modules/*))
		;;
	*)
		/usr/bin/uname.orig "$@"
		;;
esac
EOF

	cat <<"EOF" > ${chroot_dir}/tmp/vbox.sh
emerge app-emulation/virtualbox-additions
mount /usr/share/virtualbox/VBoxGuestAdditions.iso /mnt/

mv /usr/bin/uname /usr/bin/uname.orig
mv /usr/bin/uname.vbox /usr/bin/uname
chmod +x /usr/bin/uname

/mnt/VBoxLinuxAdditions.run --nox11

rm -f /usr/bin/uname
mv /usr/bin/uname.orig /usr/bin/uname

umount /mnt
emerge -C app-emulation/virtualbox-additions

rm -f /tmp/vbox.sh
EOF

	spawn_chroot "bash /tmp/vbox.sh"
}

compact_with_cleanup() {
	spawn_chroot "emerge -C ${kernel_sources}"
	spawn_chroot "rm -rf /usr/src/linux-* /var/cache/genkernel"
	spawn_chroot "rm -rf /usr/portage/distfiles/* /usr/portage/packages/*"
}

compact_with_zero_fill() {
	for part in / /usr /var; do
		spawn_chroot "cat /dev/zero > ${part}/zero.fill; sync; rm -f ${part}/zero.fill; sync"
	done
}

post_install() {
	# setup hostname
	echo "127.0.0.1 vagrant-zentoo.vagrantup.com vagrant-zentoo localhost" > ${chroot_dir}/etc/hosts
	echo "hostname=\"vagrant-zentoo\"" > ${chroot_dir}/etc/conf.d/hostname

	# setup user
	spawn_chroot "useradd -m -d /home/vagrant -g users -G wheel,portage,cron vagrant"
	spawn_chroot "echo vagrant:vagrant | chpasswd"
	spawn_chroot "curl -s -k -L https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub > /home/vagrant/.ssh/authorized_keys"

	# sudo configuration
	cat <<EOF > ${chroot_dir}/etc/sudoers
Defaults env_keep="EDITOR SSH_AUTH_SOCK"
root    ALL = (ALL) ALL
%wheel  ALL = (ALL) NOPASSWD: ALL
EOF

	# do not return with failure
	true
}
