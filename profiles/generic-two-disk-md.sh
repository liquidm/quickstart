. profiles/common/generic-md.sh

part sda 1 fd00 1G
part sda 2 fd00

part sdb 1 fd00 1G
part sdb 2 fd00

mdraid md1 --level=1 --raid-devices=2 /dev/sda1 /dev/sdb1
mdraid md2 --level=1 --raid-devices=2 /dev/sda2 /dev/sdb2
