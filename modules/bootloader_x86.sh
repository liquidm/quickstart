sanity_check_config_bootloader() {
  if [ -z "${bootloader}" ]; then
    warn "bootloader not set...assuming syslinux"
    bootloader="syslinux"
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
  APPEND root=${root}
EOB

  if ! spawn_chroot "extlinux -i /boot/syslinux"; then
    error "could not install syslinux to /boot/syslinux"
    return 1
  fi

  for device in ${bootloader_install_device}; do
    spawn "dd if=${chroot_dir}/usr/share/syslinux/mbr.bin of=${device}"
  done
}
