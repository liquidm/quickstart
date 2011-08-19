# Hetzner EQ4/6/8 profile with Software RAID
# see http://www.hetzner.de/hosting/produktmatrix/rootserver-produktmatrix-eq

. profiles/base.sh

kernel_config_uri https://raw.github.com/hollow/zentoo-quickstart/master/profiles/Hetzner-EQ468-2011-08.kconfig

bootloader_install_device /dev/sda1
bootloader_install_device /dev/sdb1

part sda 1 fd 1GB
part sda 2 fd +

part sdb 1 fd 1GB
part sdb 2 fd +

mdraid md1 --metadata=0.90 --level=1 --raid-devices=2 /dev/sda1 /dev/sdb1
mdraid md2 --metadata=0.90 --level=1 --raid-devices=2 /dev/sda2 /dev/sdb2

lvm_volgroup vg /dev/md2

format /dev/md1 ext3

mountfs /dev/md1 ext3 /

extra_packages mdadm
