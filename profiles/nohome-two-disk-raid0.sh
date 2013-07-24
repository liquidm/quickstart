. profiles/common/base.sh
. profiles/common/md.sh
. profiles/common/net-current-reboot.sh

part sda 1 fd00 1G
part sda 2 fd00

part sdb 1 fd00 1G
part sdb 2 fd00

mdraid md1 --level=1 --raid-devices=2 /dev/sda1 /dev/sdb1
mdraid md2 --level=0 --raid-devices=2 /dev/sda2 /dev/sdb2

lvm_volgroup vg /dev/md2

format /dev/md1 ext3

mountfs /dev/md1 ext3 /

lvm_logvol vg 10G opt
lvm_logvol vg 384G var
lvm_logvol vg 32G log

format /dev/vg/opt xfs
format /dev/vg/log xfs

mountfs /dev/vg/opt xfs /opt noatime
mountfs /dev/vg/log xfs /var/log noatime
