. profiles/common/base.sh

net eth0 lxc

extra_packages net-misc/bridge-utils

part sda 1 fd00 32G
part sda 2 a504

part sdb 1 fd00 32G
part sdb 2 a504

mdraid md1 --level=1 --raid-devices=2 /dev/sda1 /dev/sdb1

format /dev/md1 ext4

mountfs /dev/md1 ext4 /

post_install() {
	echo "zpool create tank mirror /dev/sda2 /dev/sdb2" > ${chroot_dir}/zpool-create.sh
}
