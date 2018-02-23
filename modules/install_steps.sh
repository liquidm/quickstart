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

prepare_rescue() {
	notify "Setting the system clock"
	spawn "/etc/init.d/ntp stop" || :
	spawn "ntpdate pool.ntp.org" || :
	spawn "hwclock -w -u" || :
	if [[ -x /usr/bin/yum ]]; then
		spawn "/usr/bin/yum -y install gdisk parted e2fsprogs xfsprogs squashfs-tools"
	fi
	if [[ -x /usr/bin/apt-get ]]; then
		spawn "apt-get update"
		spawn "apt-get install -y gdisk"
    spawn "apt-get install -y squashfs-tools"
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
        # note: if formatting is slowing down your testing, add -E nodiscard
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
  spawn "rm -f ${chroot_dir}/etc/resolv.conf; cp /etc/resolv.conf ${chroot_dir}/etc/resolv.conf; echo 'nameserver 213.186.33.99' >> /etc/resolv.conf" || die "could not copy /etc/resolv.conf into chroot"
  debug prepare_chroot "mounting proc"
  spawn "mount -t proc none ${chroot_dir}/proc" || die "could not mount proc"
  echo "${chroot_dir}/proc" >> /tmp/install.umount
  debug prepare_chroot "bind-mounting /dev"
  spawn "mount -o bind /dev ${chroot_dir}/dev" || die "could not bind-mount /dev"
  echo "${chroot_dir}/dev" >> /tmp/install.umount
  debug prepare_chroot "bind-mounting /sys"
  spawn "mount -o bind /sys ${chroot_dir}/sys" || die "could not bind-mount /sys"
  echo "${chroot_dir}/sys" >> /tmp/install.umount

  debug prepare_chroot "setting grub defaults"
  cat > ${chroot_dir}/etc/default/grub.d/60-liquidm-settings.cfg << EOF
GRUB_CMDLINE_LINUX_DEFAULT="console=tty1 net.ifnames=0 biosdevname=0"
EOF
}

install_apt_tree() {
  spawn_chroot "apt-get update" || die "could not fetch apt tree"
  spawn_chroot "apt-get remove -y cloud-guest-utils rsyslog lxcfs open-iscsi"

}

set_ssh_authorized_key() {
  if [ -n "${ssh_authorized_key}" ]; then
    mkdir -p "${chroot_dir}/root/.ssh/"
    echo "${ssh_authorized_key}" > "${chroot_dir}/root/.ssh/authorized_keys"
  fi
  spawn_chroot "ssh-keygen -A"
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
    spawn "/usr/share/mdadm/mkconf > ${chroot_dir}/etc/mdadm/mdadm.conf"

    # stock kernel
    spawn_chroot "DEBIAN_FRONTEND=noninteractive apt-get -y install ${kernel_image}" || die "could not install kernel"

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
  local device=$(ip route | awk '/default/ { print $5 }')
  local gateway=$(ip route list | grep default | awk '{ print $3 }')
  local ipaddress=$(ip addr show dev ${device} | grep 'inet .*global' | awk '{ print $2 }')
  cat >> ${chroot_dir}/etc/systemd/network/default.network << EOF
[Match]
Name=${device}

[Network]
Address=${ipaddress}
Gateway=${gateway}
IPv6AcceptRouterAdvertisements=false
EOF

  spawn_chroot "touch /etc/udev/rules.d/80-net-name-slot.rules" || die "failed to touch udev rules"

  spawn_chroot "systemctl disable systemd-networkd.service" || die "failed to disable networkd"
  spawn_chroot "systemctl enable systemd-networkd.service" || die "failed to enable networkd"

  spawn_chroot "systemctl disable ssh.service" || die "failed to disable sshd"
  spawn_chroot "systemctl enable ssh.service" || die "failed to enable sshd"
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
