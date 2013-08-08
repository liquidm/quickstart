lvm_logvol vg 10G opt
lvm_logvol vg 64G var
lvm_logvol vg 32G log

format /dev/vg/opt xfs
format /dev/vg/log xfs

mountfs /dev/vg/opt xfs /opt noatime
mountfs /dev/vg/log xfs /var/log noatime
