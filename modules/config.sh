part() {
  local drive=$1
  local minor=$2
  local type=$3
  local size=$4

  drive=$(echo ${drive} | sed -e 's:^/dev/::' -e 's:/:_:g')
  local drive_temp="partitions_${drive}"
  local tmppart="${minor}:${type}:${size}"
  if [ -n "$(eval echo \${${drive_temp}})" ]; then
    eval "${drive_temp}=\"$(eval echo \${${drive_temp}}) ${tmppart}\""
  else
    eval "${drive_temp}=\"${tmppart}\""
  fi
  debug part "${drive_temp} is now: $(eval echo \${${drive_temp}})"
}

mdraid() {
  local array=$1
  shift
  local arrayopts=$@

  eval "mdraid_${array}=\"${arrayopts}\""
}

format() {
  local device=$1
  local fs=$2

  local tmpformat="${device}:${fs}"
  if [ -n "${format}" ]; then
    format="${format} ${tmpformat}"
  else
    format="${tmpformat}"
  fi
}

mountfs() {
  local device=$1
  local type=$2
  local mountpoint=$3
  local mountopts=$4

  [ -z "${mountopts}" ] && mountopts="defaults"
  [ -z "${mountpoint}" ] && mountpoint="none"
  local tmpmount="${device}:${type}:${mountpoint}:${mountopts}"
  if [ -n "${localmounts}" ]; then
    localmounts="${localmounts} ${tmpmount}"
  else
    localmounts="${tmpmount}"
  fi
}

rootpw() {
  local pass=$1

  root_password="${pass}"
}

stage_uri() {
  local uri=$1

  stage_uri="${uri}"
}

tree_type() {
  local type=$1
  local uri=$2
  local branch=$3

  tree_type="${type}"
  portage_snapshot_uri="${uri}"
  portage_snapshot_branch="${branch}"
}

mirror() {
  distfiles_mirror=$1
  portage_mirror=$2
}

chroot_dir() {
  local dir=$1

  chroot_dir="${dir}"
}

extra_packages() {
  local pkg=$@

  if [ -n "${extra_packages}" ]; then
    extra_packages="${extra_packages} ${pkg}"
  else
    extra_packages="${pkg}"
  fi
}

kernel_image() {
  local pkg=$1

  kernel_image="${pkg}"
}

timezone() {
  local tz=$1

  timezone="${tz}"
}

net() {
  local device=$1
  local ipdhcp=$2
  local gateway=$3

  local tmpnet="${device}|${ipdhcp}|${gateway}"
  if [ -n "${net_devices}" ]; then
    net_devices="${net_devices} ${tmpnet}"
  else
    net_devices="${tmpnet}"
  fi
}

logfile() {
  local file=$1

  logfile=${file}
}

shutdown() {
  shutdown="yes"
}

reboot() {
  reboot="yes"
}

verbose() {
  verbose=1
}

sanity_check_config() {
  local fatal=0

  debug sanity_check_config "$(set | grep '^[a-z]')"

  if [ -z "${chroot_dir}" ]; then
    error "chroot_dir is not defined (this can only happen if you set it to a blank string)"
    fatal=1
  fi
  if [ -z "${stage_uri}" ]; then
    error "you must specify a stage_uri"
    fatal=1
  fi
  if [ -z "${tree_type}" ]; then
    warn "tree_type not set...defaulting to sync"
    tree_type="sync"
  fi
  if [ "${tree_type}" = "snapshot" -a -z "${portage_snapshot_uri}" ]; then
    error "you must specify a portage snapshot URI with tree_type snapshot"
    fatal=1
  fi
  if [ -z "${root_password}" ]; then
    error "you must specify a root password"
    fatal=1
  fi
  if [ -z "${timezone}" ]; then
    warn "timezone not set...assuming UTC"
    timezone=UTC
  fi

  debug sanity_check_config "$(set | grep '^[a-z]')"

  [ "${fatal}" = "1" ] && exit 1
}
