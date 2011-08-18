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

configure_bootloader_grub() {
  local root="$(get_boot_and_root | cut -d '|' -f2)"

  # Clear out any existing device.map for a "clean" start
  rm ${chroot_dir}/boot/grub/device.map &>/dev/null

  echo -e "default 0\ntimeout 10\n" > ${chroot_dir}/boot/grub/grub.conf

  for boot in ${bootloader_install_device}; do
    local boot_device="$(get_device_and_partition_from_devnode ${boot} | cut -d '|' -f1)"
    local boot_minor="$(get_device_and_partition_from_devnode ${boot} | cut -d '|' -f2)"

    echo "title Gentoo Linux on ${boot_device}" >> ${chroot_dir}/boot/grub/grub.conf
    local grub_device="$(map_device_to_grub_device ${boot_device})"
    if [ -z "${grub_device}" ]; then
      error "could not map boot device ${boot_device} to grub device"
      return 1
    fi
    echo -en "root (${grub_device},$(expr ${boot_minor} - 1))\nkernel /boot/kernel " >> ${chroot_dir}/boot/grub/grub.conf
    echo -e "root=${root}\n" >> ${chroot_dir}/boot/grub/grub.conf
  done

  for boot in ${bootloader_install_device}; do
    local boot_device="$(get_device_and_partition_from_devnode ${boot} | cut -d '|' -f1)"
    local boot_minor="$(get_device_and_partition_from_devnode ${boot} | cut -d '|' -f2)"
    local grub_device="$(map_device_to_grub_device ${boot_device})"
    if ! spawn_chroot "echo 'root (${grub_device},$(expr ${boot_minor} - 1))\nsetup (${grub_device})\nquit' | /sbin/grub --batch --no-floppy"; then
      error "could not install grub to ${boot_device}"
      return 1
    fi
  done
}
