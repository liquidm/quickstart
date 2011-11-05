. profiles/base.sh

bootloader_install_device /dev/sda1

part sda 1 fd 1GB
part sda 2 fd +

lvm_volgroup vg /dev/sda2

format /dev/sda1 ext3

mountfs /dev/sda1 ext3 /
