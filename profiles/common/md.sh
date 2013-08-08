extra_packages mdadm

lvm_volgroup vg /dev/md2

format /dev/md1 ext3

mountfs /dev/md1 ext3 /
