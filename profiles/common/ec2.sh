bootloader none

need_mbr

net eth0 dhcp

setup_pv_grub() {
    local root_device=$1
    local root_uuid=$(blkid -s UUID -o value ${root_device})

    mkdir -p /mnt/gentoo/boot/grub
    cat <<EOG > /mnt/gentoo/boot/grub/menu.lst
default 0
timeout 10

title Gentoo Linux
root (hd0,0)
kernel /boot/kernel root=UUID=${root_uuid} ro domdadm dolvm
initrd /boot/initramfs
EOG
}
