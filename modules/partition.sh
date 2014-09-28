create_disklabel() {
  local device=$1

  debug create_disklabel "creating new gpt disklabel"
  sgdisk -Z -g ${device}

  # add bios boot partition for good measure
  sgdisk -n "128:-32M:" -t "128:ef02" -c "128:BIOS boot partition" ${device}

  return $?
}

add_partition() {
  local device=$1
  local minor=$2
  local type=$3
  local size=$4

  sgdisk -n "${minor}::+${size}" -t "${minor}:${type}" -c "${minor}:Linux filesystem" ${device}
  return $?
}
