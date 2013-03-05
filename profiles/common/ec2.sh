need_mbr

net eth0 dhcp

setup_pv_grub() {
    mkdir -p /mnt/gentoo/boot/grub
    cat <<EOG > /mnt/gentoo/boot/grub/menu.lst
default 0
timeout 10

title Gentoo Linux
root (hd0,0)
kernel /boot/kernel root=/dev/xvda1 ro domdadm dolvm
initrd /boot/initramfs
EOG
}
