. profiles/common/base.sh
. profiles/common/extra-volumes.sh
. profiles/common/net-current-reboot.sh

part sda 1 fd00 1G
part sda 2 fd00

lvm_volgroup vg /dev/sda2

format /dev/sda1 ext3

mountfs /dev/sda1 ext3 /
