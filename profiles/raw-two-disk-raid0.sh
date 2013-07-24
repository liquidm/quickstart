. profiles/nohome-two-disk-raid0.sh

part sdc 1 8300
part sdd 1 8300

format /dev/sdc1 xfs
format /dev/sdd1 xfs

mountfs /dev/sdc1 xfs /mnt/hadoop/a
mountfs /dev/sdd1 xfs /mnt/hadoop/b
