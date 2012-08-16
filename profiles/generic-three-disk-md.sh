. profiles/common/base.sh
. profiles/common/extra-volumes.sh
. profiles/common/md.sh
. profiles/common/net-current-reboot.sh

bootloader_install_device /dev/sda1
bootloader_install_device /dev/sdb1
bootloader_install_device /dev/sdc1

part sda 1 fd 1GB
part sda 2 fd +

part sdb 1 fd 1GB
part sdb 2 fd +

part sdc 1 fd 1GB
part sdc 2 fd +

mdraid md1 --metadata=0.90 --level=1 --raid-devices=3 /dev/sda1 /dev/sdb1 /dev/sdc1
mdraid md2 --metadata=0.90 --level=5 --raid-devices=3 /dev/sda2 /dev/sdb2 /dev/sdc2

lvm_volgroup vg /dev/md2

format /dev/md1 ext3

mountfs /dev/md1 ext3 /
