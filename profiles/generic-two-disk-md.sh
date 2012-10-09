. profiles/common/base.sh
. profiles/common/extra-volumes.sh
. profiles/common/md.sh
. profiles/common/net-current-reboot.sh

bootloader_install_device /dev/sda1
bootloader_install_device /dev/sdb1

part sda 1 fd00 1G
part sda 2 fd00

part sdb 1 fd00 1G
part sdb 2 fd00

mdraid md1 --level=1 --raid-devices=2 /dev/sda1 /dev/sdb1
mdraid md2 --level=1 --raid-devices=2 /dev/sda2 /dev/sdb2

lvm_volgroup vg /dev/md2

format /dev/md1 ext3

mountfs /dev/md1 ext3 /
