. profiles/common/base.sh
. profiles/common/extra-volumes.sh
. profiles/common/net-current-reboot.sh

bootloader_install_device /dev/sdc

part sdc 1 fd00 1G
part sdc 2 fd00

lvm_volgroup vg /dev/sdc2

format /dev/sdc1 ext3

mountfs /dev/sdc1 ext3 /
