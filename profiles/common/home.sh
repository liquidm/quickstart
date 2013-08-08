lvm_logvol vg 10G home

format /dev/vg/home xfs

mountfs /dev/vg/home xfs /home noatime
