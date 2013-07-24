. profiles/nohome-two-disk-raid0.sh

part sdc 1 fd00 1G
part sdc 2 8300

part sdd 1 fd00 1G
part sdd 2 8300

mdraid md1 --level=1 --raid-devices=4 /dev/sda1 /dev/sdb1 /dev/sdc1 /dev/sdd1

format /dev/sdc2 xfs
format /dev/sdd2 xfs

mountfs /dev/sdc2 xfs /mnt/hadoop/a
mountfs /dev/sdd2 xfs /mnt/hadoop/b
