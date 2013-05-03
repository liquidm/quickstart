. profiles/common/base.sh
. profiles/common/extra-volumes.sh
. profiles/common/net-current-reboot.sh

part sdc 1 fd00 1G
part sdc 2 fd00

format /dev/sdc1 ext3
mountfs /dev/sdc1 ext3 /

lvm_volgroup vg /dev/sdc2

format /dev/sda xfs
mountfs /dev/sda xfs /mnt/hadoop/a noatime

format /dev/sdb xfs
mountfs /dev/sdb xfs /var/tmp/hadoop noatime

lvm_logvol vg 500G javatmp
format /dev/vg/javatmp xfs
mountfs /dev/vg/javatmp xfs /var/tmp/java noatime
