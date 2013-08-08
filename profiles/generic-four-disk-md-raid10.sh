. profiles/common/generic-four-disk-md.sh

mdraid md2 --level=10 --raid-devices=4 /dev/sda2 /dev/sdb2 /dev/sdc2 /dev/sdd2
