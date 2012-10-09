. profiles/common/base.sh
. profiles/common/extra-volumes.sh
. profiles/common/net-current-reboot.sh

bootloader_install_device /dev/sda1

part sda 1 fd00 1G
part sda 2 fd00

lvm_volgroup vg /dev/sda2

format /dev/sda1 ext3

mountfs /dev/sda1 ext3 /
