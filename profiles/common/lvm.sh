lvm_logvol vg 10G usr
lvm_logvol vg 10G var

format /dev/vg/usr xfs
format /dev/vg/var xfs

mountfs /dev/vg/usr xfs /usr noatime
mountfs /dev/vg/var xfs /var noatime

extra_packages lvm2
