lvm_logvol vg 10G home
lvm_logvol vg 10G opt
lvm_logvol vg 64G var
lvm_logvol vg 32G log

format /dev/vg/home xfs
format /dev/vg/opt xfs
format /dev/vg/var xfs
format /dev/vg/log xfs

mountfs /dev/vg/home xfs /home noatime
mountfs /dev/vg/opt xfs /opt noatime
mountfs /dev/vg/var xfs /var noatime
mountfs /dev/vg/log xfs /var/log noatime
