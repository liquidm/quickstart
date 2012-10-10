sanity_check_config_bootloader() {
  if [ -z "${bootloader}" ]; then
    debug sanity_check_config_bootloader "bootloader not set...assuming grub"
    bootloader="grub"
  fi
}

configure_bootloader_syslinux() {
  local boot_root="$(get_boot_and_root)"
  local boot="$(echo ${boot_root} | cut -d '|' -f1)"
  local root="$(echo ${boot_root} | cut -d '|' -f2)"

  mkdir ${chroot_dir}/boot/syslinux
  cat <<EOB > ${chroot_dir}/boot/syslinux/syslinux.cfg
DEFAULT linux
LABEL linux
  KERNEL /boot/kernel
  INITRD /boot/initramfs
  APPEND root=${root} ro quiet dolvm
EOB

  if ! spawn_chroot "extlinux -i /boot/syslinux"; then
    error "could not install syslinux to /boot/syslinux"
    return 1
  fi

  for device in ${bootloader_install_device}; do
    spawn "dd if=${chroot_dir}/usr/share/syslinux/mbr.bin of=${device}"
  done
}

configure_bootloader_grub() {
  spawn_chroot "sed -e '/^GRUB_CMDLINE_LINUX=/s/=.*/=\"domdadm dolvm\"/' /etc/default/grub" || die "cannot fix grub defaults"
  spawn_chroot "mkdir -p /boot/grub2" || die "cannot create /boot/grub2"
  spawn_chroot "grub2-mkconfig -o /boot/grub2/grub.cfg" || die "cannot create grub.cfg"

  for device in ${bootloader_install_device}; do
    if ! spawn_chroot "grub2-install ${device}"; then
      error "could not install grub to ${device}"
      return 1
    fi
  done
}
