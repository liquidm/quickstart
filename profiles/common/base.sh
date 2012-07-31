stage_uri http://www.zentoo.org/downloads/amd64/base-current.tar.bz2
tree_type snapshot http://www.zentoo.org/downloads/snapshots/portage-current.tar.bz2
mirror http://mirror.zentoo.org

rootpw tux
timezone Europe/Berlin

kernel_sources zentoo-sources
kernel_config_uri https://raw.github.com/zentoo/quickstart/master/profiles/3.2.14-zentoo-generic.kconfig

lvm_logvol vg 10G home
lvm_logvol vg 10G opt
lvm_logvol vg 10G usr
lvm_logvol vg 64G var
lvm_logvol vg 32G log

format /dev/vg/home xfs
format /dev/vg/opt xfs
format /dev/vg/usr xfs
format /dev/vg/var xfs
format /dev/vg/log xfs

mountfs /dev/vg/home xfs /home noatime
mountfs /dev/vg/opt xfs /opt noatime
mountfs /dev/vg/usr xfs /usr noatime
mountfs /dev/vg/var xfs /var noatime
mountfs /dev/vg/log xfs /var/log noatime

extra_packages lvm2 xfsprogs

rcadd devfs sysinit
rcadd udev sysinit
rcadd lvm boot
rcadd sshd default
rcadd udev-postmount default
