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
    if [ "${need_mbr}" = "yes" ]; then
      notify "Converting to MBR"
      convert_to_mbr ${device}
    fi
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

setup_lvm() {
  # make sure we have a writable /var/lock for LVM
  mount -t tmpfs none /var/lock
  echo "/var/lock" >> /tmp/install.umount

  for volgroup in $(set | grep '^lvm_volgroup_' | cut -d= -f1 | sed -e 's:^lvm_volgroup_::' | sort); do
    local volgroup_temp="lvm_volgroup_${volgroup}"
    local volgroup_devices="$(eval echo \${${volgroup_temp}})"
    for device in ${volgroup_devices}; do
      spawn "pvcreate -ffy ${device}" || die "could not run 'pvcreate' on ${device}"
    done
    spawn "vgcreate ${volgroup} ${volgroup_devices}" || die "could not create volume group '${volgroup}' from devices: ${volgroup_devices}"
  done

  for logvol in $(set | grep '^lvm_logvol_' | cut -d= -f1 | sed -e 's:^lvm_logvol_::' | sort); do
    local volgroup="$(echo ${logvol} | cut -d '_' -f1)"
    local name="$(echo ${logvol} | cut -d '_' -f2)"
    local size="$(eval echo \${lvm_logvol_${logvol}})"
    spawn "lvcreate -Zn -L${size} -n${name} ${volgroup}" || die "could not create logical volume '${name}' with size ${size} in volume group '${volgroup}'"
  done

  spawn "vgscan --mknodes" || die "could not create lvm device nodes"
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
        ext2|ext3|ext4|xfs|btrfs)
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
  elif [ "${tree_type}" = "git-snapshot" ]; then
    fetch "${portage_snapshot_uri}" "${chroot_dir}/$(get_filename_from_uri ${portage_snapshot_uri})" || die "could not fetch portage snapshot"
    unpack_tarball "${chroot_dir}/$(get_filename_from_uri ${portage_snapshot_uri})" "${chroot_dir}/usr" || die "could not unpack portage snapshot"
    spawn_chroot "git --git-dir=/usr/portage/.git --work-tree=/usr/portage checkout ${portage_snapshot_branch}" || die "could not checkout portage branch"
    spawn_chroot "emerge --sync" || die "could not sync portage tree"
  elif [ "${tree_type}" = "none" ]; then
    warn "'none' specified...skipping"
  else
    die "Unrecognized tree_type: ${tree_type}"
  fi
}

set_root_password() {
  if [ -n "${root_password_hash}" ]; then
    spawn_chroot "echo 'root:${root_password_hash}' | chpasswd -e" || die "could not set root password"
  elif [ -n "${root_password}" ]; then
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
  for mount in ${netmounts}; do
    local export=$(echo ${mount} | cut -d '|' -f1)
    local type=$(echo ${mount} | cut -d '|' -f2)
    local mountpoint=$(echo ${mount} | cut -d '|' -f3)
    local mountopts=$(echo ${mount} | cut -d '|' -f4)
    echo -e "${export}\t${mountpoint}\t${type}\t${mountopts}\t0 0" >> ${chroot_dir}/etc/fstab
  done
}

setup_network_post() {
  if [ -n "${net_devices}" ]; then
    for net_device in ${net_devices}; do
      local device="$(echo ${net_device} | cut -d '|' -f1)"
      local mode="$(echo ${net_device} | cut -d '|' -f2)"
      local netctl=${chroot_dir}/etc/netctl/${device}

      cat > ${netctl} << EOF
Description='${device}'
Interface=${device}
Connection=ethernet
ForceConnect=yes
EOF

      case $mode in
      dhcp)
        cat >> ${netctl} << EOF
IP=dhcp
EOF

      ;;
      current)
        local ipaddress=$(ip addr show dev ${device} | grep 'inet .*global' | awk '{ print $2 }' | awk -F/ '{ print $1 }')
        local gateway=$(ip route list | grep default.*${device} | awk '{ print $3 }')
        cat >> ${netctl} << EOF
IP=static
Address=('${ipaddress}/32')
Routes=('${gateway}')
Gateway='${gateway}'
DNS=('8.8.8.8' '8.8.4.4')
EOF

      ;;
      esac

      spawn_chroot "netctl enable ${device}"
    done
  fi
  spawn_chroot "touch /etc/udev/rules.d/80-net-name-slot.rules"
  spawn_chroot "systemctl enable sshd.service"
}

install_extra_packages() {
  if [ -z "${extra_packages}" ]; then
    debug install_extra_packages "no extra packages specified"
  else
    spawn_chroot "emerge -n ${extra_packages}" || die "could not emerge extra packages"
  fi
}

run_post_install_script() {
  if [ -n "${post_install_script_uri}" ]; then
    fetch "${post_install_script_uri}" "${chroot_dir}/var/tmp/post_install_script" || die "could not fetch post-install script"
    chmod +x "${chroot_dir}/var/tmp/post_install_script"
    spawn_chroot "/var/tmp/post_install_script" || die "error running post-install script"
    spawn "rm ${chroot_dir}/var/tmp/post_install_script"
  elif $(isafunc post_install); then
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

failure_cleanup() {
  spawn "mv ${logfile} ${logfile}.failed" || warn "could not move ${logfile} to ${logfile}.failed"
  if [ -e /tmp/install.umount ]; then
    for mnt in $(sort -r /tmp/install.umount); do
      spawn "umount ${mnt}" || warn "could not unmount ${mnt}"
    done
    rm /tmp/install.umount 2>/dev/null
  fi
  if [ -e /tmp/install.swapoff ]; then
    for swap in $(</tmp/install.swapoff); do
      spawn "swapoff ${swap}" || warn "could not deactivate swap on ${swap}"
    done
    rm /tmp/install.swapoff 2>/dev/null
  fi
  for array in $(set | grep '^mdraid_' | cut -d= -f1 | sed -e 's:^mdraid_::' | sort); do
    spawn "mdadm --manage --stop /dev/${array}" || warn "could not stop mdraid array ${array}"
  done
}
