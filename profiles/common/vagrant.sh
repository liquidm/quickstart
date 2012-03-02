post_install() {
	# setup hostname
	echo "127.0.0.1 vagrant-zentoo.vagrantup.com vagrant-zentoo localhost" > /etc/hosts
	echo "hostname=\"vagrant-zentoo\"" > /etc/conf.d/hostname

	# setup user
	useradd -d /home/vagrant -g users -G wheel,portage,cron vagrant
	echo "vagrant:vagrant" | chpasswd
	curl -s -k -L https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub > /home/vagrant/.ssh/authorized_keys

	# sudo configuration
	cat <<EOF > /etc/sudoers
Defaults env_keep="EDITOR SSH_AUTH_SOCK"
root    ALL = (ALL) ALL
%wheel  ALL = (ALL) NOPASSWD: ALL
EOF

	# install guest additions
	emerge app-emulation/virtualbox-additions
	mount /usr/share/virtualbox/VBoxGuestAdditions.iso /mnt/
	/mnt/VBoxLinuxAdditions.run --nox11
	umount /mnt
	emerge -C app-emulation/virtualbox-additions
}
