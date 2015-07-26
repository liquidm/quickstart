run_pre_install_script() {
  if [ -n "${pre_install_script_uri}" ]; then
    fetch "${pre_install_script_uri}" "${chroot_dir}/var/tmp/pre_install_script" || die "could not fetch pre-install script"
    chmod +x "${chroot_dir}/var/tmp/pre_install_script"
    spawn_chroot "/var/tmp/pre_install_script" || die "error running pre-install script"
    spawn "rm ${chroot_dir}/var/tmp/pre_install_script"
  elif $(isafunc pre_install); then
    pre_install || die "error running pre_install()"
  else
    debug run_pre_install_script "no pre-install script set"
  fi
}

partition() {
  for device in $(set | grep '^partitions_' | cut -d= -f1 | sed -e 's:^partitions_::'); do
    debug partition "device is ${device}"
    local device_temp="partitions_${device}"
    local device="/dev/$(echo "${device}" | sed  -e 's:_:/:g')"
    create_disklabel ${device} || die "could not create disklabel for device ${device}"
    for partition in $(eval echo \${${device_temp}}); do
      debug partition "partition is ${partition}"
      local minor=$(echo ${partition} | cut -d: -f1)
      local type=$(echo ${partition} | cut -d: -f2)
      local size=$(echo ${partition} | cut -d: -f3)
      add_partition "${device}" "${minor}" "${type}" "${size}" || die "could not add partition ${minor} to device ${device}"
    done
    partprobe
    sleep 5
  done
}

setup_md_raid() {
  for array in $(set | grep '^mdraid_' | cut -d= -f1 | sed -e 's:^mdraid_::' | sort); do
    local array_temp="mdraid_${array}"
    local arrayopts=$(eval echo \${${array_temp}})
    local arraynum=$(echo ${array} | sed -e 's:^md::')
    if [ ! -e "/dev/md${arraynum}" ]; then
      spawn "mknod /dev/md${arraynum} b 9 ${arraynum}" || die "could not create device node for mdraid array ${array}"
    fi
    if mdadm --version 2>&1 | grep -q 3.2.3; then
      spawn "mdadm --create --run --metadata=0.90 /dev/${array} ${arrayopts}" || die "could not create mdraid array ${array}"
    else
      spawn "mdadm --create --run /dev/${array} ${arrayopts}" || die "could not create mdraid array ${array}"
    fi
  done
}

format_devices() {
  for device in ${format}; do
    local devnode=$(echo ${device} | cut -d: -f1)
    local fs=$(echo ${device} | cut -d: -f2)
    local formatcmd=""
    case "${fs}" in
      swap)
        formatcmd="mkswap ${devnode}"
        ;;
      ext2|ext3|ext4)
        formatcmd="mkfs.${fs} -F ${devnode}"
        ;;
      xfs)
        formatcmd="mkfs.${fs} -f ${devnode}"
        ;;
      *)
        formatcmd=""
        warn "don't know how to format ${devnode} as ${fs}"
    esac
    if [ -n "${formatcmd}" ]; then
      spawn "${formatcmd}" || die "could not format ${devnode} with command: ${formatcmd}"
    fi
  done
}

mount_partitions() {
  if [ -z "${localmounts}" ]; then
    warn "no local mounts specified. this is a bit unusual, but you're the boss"
  else
    rm /tmp/install.mount /tmp/install.umount /tmp/install.swapoff 2>/dev/null
    for mount in ${localmounts}; do
      debug mount_partitions "mount is ${mount}"
      local devnode=$(echo ${mount} | cut -d ':' -f1)
      local type=$(echo ${mount} | cut -d ':' -f2)
      local mountpoint=$(echo ${mount} | cut -d ':' -f3)
      local mountopts=$(echo ${mount} | cut -d ':' -f4)
      [ -n "${mountopts}" ] && mountopts="-o ${mountopts}"
      case "${type}" in
        swap)
          spawn "swapon ${devnode}" || warn "could not activate swap ${devnode}"
          echo "${devnode}" >> /tmp/install.swapoff
          ;;
        ext2|ext3|ext4|xfs)
          echo "mount -t ${type} ${devnode} ${chroot_dir}${mountpoint} ${mountopts}" >> /tmp/install.mount
          echo "${chroot_dir}${mountpoint}" >> /tmp/install.umount
          ;;
      esac
    done
    sort -k5 /tmp/install.mount | while read mount; do
      mkdir -p $(echo ${mount} | awk '{ print $5; }')
      spawn "${mount}" || die "could not mount with: ${mount}"
    done
  fi
}

unpack_stage_tarball() {
  fetch "${stage_uri}" "${chroot_dir}/$(get_filename_from_uri ${stage_uri})" || die "Could not fetch stage tarball"
  unpack_tarball "${chroot_dir}/$(get_filename_from_uri ${stage_uri})" "${chroot_dir}" 1 || die "Could not unpack stage tarball"
}

prepare_chroot() {
  debug prepare_chroot "copying /etc/resolv.conf into chroot"
  spawn "cp /etc/resolv.conf ${chroot_dir}/etc/resolv.conf" || die "could not copy /etc/resolv.conf into chroot"
  debug prepare_chroot "mounting proc"
  spawn "mount -t proc none ${chroot_dir}/proc" || die "could not mount proc"
  echo "${chroot_dir}/proc" >> /tmp/install.umount
  debug prepare_chroot "bind-mounting /dev"
  spawn "mount -o bind /dev ${chroot_dir}/dev" || die "could not bind-mount /dev"
  echo "${chroot_dir}/dev" >> /tmp/install.umount
  debug prepare_chroot "bind-mounting /sys"
  spawn "mount -o bind /sys ${chroot_dir}/sys" || die "could not bind-mount /sys"
  echo "${chroot_dir}/sys" >> /tmp/install.umount
}

install_portage_tree() {
  if [ -n "${distfiles_mirror}" ]; then
    echo GENTOO_MIRRORS=\"${distfiles_mirror}\" >> ${chroot_dir}/etc/portage/make.conf
  fi
  if [ -n "${portage_mirror}" ]; then
    echo SYNC=\"${portage_mirror}\" >> ${chroot_dir}/etc/portage/make.conf
  fi
  debug install_portage_tree "tree_type is ${tree_type}"
  if [ "${tree_type}" = "sync" ]; then
    spawn_chroot "emerge --sync" || die "could not sync portage tree"
  elif [ "${tree_type}" = "snapshot" ]; then
    fetch "${portage_snapshot_uri}" "${chroot_dir}/$(get_filename_from_uri ${portage_snapshot_uri})" || die "could not fetch portage snapshot"
    unpack_tarball "${chroot_dir}/$(get_filename_from_uri ${portage_snapshot_uri})" "${chroot_dir}/usr" || die "could not unpack portage snapshot"
    spawn_chroot "emerge --sync" || die "could not sync portage tree"
  elif [ "${tree_type}" = "webrsync" ]; then
    spawn_chroot "emerge-webrsync" || die "could not emerge-webrsync"
  elif [ "${tree_type}" = "none" ]; then
    warn "'none' specified...skipping"
  else
    die "Unrecognized tree_type: ${tree_type}"
  fi
  if $(isafunc post_install_portage); then
    post_install_portage || die "error running post_install_portage()"
  else
    debug install_portage_tree "no post_install_portage script set"
  fi
}

set_root_password() {
  if [ -n "${root_password}" ]; then
    spawn_chroot "echo 'root:${root_password}' | chpasswd" || die "could not set root password"
  fi
}

set_timezone() {
  [ -e "${chroot_dir}/etc/localtime" ] && spawn "rm ${chroot_dir}/etc/localtime" || die "could not remove existing /etc/localtime"
  spawn "cp ${chroot_dir}/usr/share/zoneinfo/${timezone} ${chroot_dir}/etc/localtime" || die "could not set timezone"
  echo "${timezone}" > "${chroot_dir}/etc/timezone"
}

install_kernel() {
  if [ "${kernel_image}" = "none" ]; then
    debug install_kernel "kernel_image is 'none'...skipping kernel build"
  else
    spawn_chroot "emerge -n ${kernel_image}" || die "could not emerge kernel sources"
    spawn_chroot "emerge --config ${kernel_image}" || die "could not install bootloader"
  fi
}

setup_fstab() {
  echo "# generated by quickstart on $(date)" > ${chroot_dir}/etc/fstab
  for mount in ${localmounts}; do
    debug setup_fstab "mount is ${mount}"
    local devnode=$(echo ${mount} | cut -d ':' -f1)
    local devuuid=$(blkid -s UUID -o value ${devnode})
    local type=$(echo ${mount} | cut -d ':' -f2)
    local mountpoint=$(echo ${mount} | cut -d ':' -f3)
    local mountopts=$(echo ${mount} | cut -d ':' -f4)
    if [ "${mountpoint}" == "/" ]; then
      devnode="/dev/root"
      local dump_pass="0 1"
    elif [ "${mountpoint}" == "/boot" -o "${mountpoint}" == "/boot/" ]; then
      local dump_pass="1 2"
    else
      local dump_pass="0 0"
    fi
    echo -e "UUID=${devuuid}\t${mountpoint}\t${type}\t${mountopts}\t${dump_pass}" >> ${chroot_dir}/etc/fstab
  done
}

setup_network_post() {
  if [ -n "${net_devices}" ]; then
    for net_device in ${net_devices}; do
      local device="$(echo ${net_device} | cut -d '|' -f1)"
      local mode="$(echo ${net_device} | cut -d '|' -f2)"

      case $mode in
      dhcp)
        cat >> ${chroot_dir}/etc/systemd/network/${device}.network << EOF
[Match]
Name=${device}

[Network]
DHCP=both
EOF
        ;;
      current)
        local gateway=$(ip route list | grep default | awk '{ print $3 }')
        local ipaddress=$(ip addr show dev ${device} | grep 'inet .*global' | awk '{ print $2 }')
        cat >> ${chroot_dir}/etc/systemd/network/${device}.network << EOF
[Match]
Name=${device}

[Network]
Address=${ipaddress}
Gateway=${gateway}
EOF
        ;;
      lxc)
        local gateway=$(ip route list | grep default | awk '{ print $3 }')
        local ipaddress=$(ip addr show dev ${device} | grep 'inet .*global' | awk '{ print $2 }')
        spawn_chroot "emerge -n netctl" || die "could not emerge netctl"
        cat >> ${chroot_dir}/etc/netctl/lxcbr0 << EOF
Description='lxcbr0'
Interface=lxcbr0
Connection=bridge
BindsToInterfaces=(${device})
IP=static
Address=('${ipaddress}')
Gateway='${gateway}'
DNS=('8.8.8.8' '8.8.4.4')
EOF
        spawn_chroot "netctl enable lxcbr0" || die "could not enable network interface"
        ;;
      esac

    done
  fi

  spawn_chroot "touch /etc/udev/rules.d/80-net-name-slot.rules" || die "failed to touch udev rules"

  spawn_chroot "systemctl disable systemd-networkd.service" || die "failed to disable networkd"
  spawn_chroot "systemctl enable systemd-networkd.service" || die "failed to enable networkd"

  spawn_chroot "systemctl disable sshd.service" || die "failed to disable sshd"
  spawn_chroot "systemctl enable sshd.service" || die "failed to enable sshd"
}

install_extra_packages() {
  if [ -z "${extra_packages}" ]; then
    debug install_extra_packages "no extra packages specified"
  else
    spawn_chroot "emerge -n ${extra_packages}" || die "could not emerge extra packages"
  fi
}

run_post_install_script() {
  if $(isafunc post_install); then
    post_install || die "error running post_install()"
  else
    debug run_post_install_script "no post-install script set"
  fi
}

finishing_cleanup() {
  rm -f "${chroot_dir}/$(get_filename_from_uri ${stage_uri})" || warn "Could not remove stage tarball"
  rm -f "${chroot_dir}/$(get_filename_from_uri ${portage_snapshot_uri})" || warn "could not remove portage tarball"
  spawn "cp ${logfile} ${chroot_dir}/root/$(basename ${logfile})" || warn "could not copy install logfile into chroot"
  if [ -e /tmp/install.umount ]; then
    for mnt in $(sort -r /tmp/install.umount); do
      spawn "umount ${mnt}" || warn "could not unmount ${mnt}"
      rm /tmp/install.umount 2>/dev/null
    done
  fi
  if [ -e /tmp/install.swapoff ]; then
    for swap in $(</tmp/install.swapoff); do
      spawn "swapoff ${swap}" || warn "could not deactivate swap on ${swap}"
    done
    rm /tmp/install.swapoff 2>/dev/null
  fi
}
