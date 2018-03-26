create_disklabel() {
  local device=$1

  debug create_disklabel "creating new gpt disklabel"
  debug create_disklabel "sgdisk -Z -g ${device}"
  sgdisk -Z -g ${device}
  partprobe ${device}
  sleep 5

  # add bios boot partition for good measure
  debug create_disklabel "sgdisk -n \"128:-32M:\" -t \"128:ef02\" -c \"128:BIOS boot partition\" ${device}"
  sgdisk -n "128:-32M:" -t "128:ef02" -c "128:BIOS boot partition" ${device}

  return $?
}

add_partition() {
  local device=$1
  local minor=$2
  local type=$3
  local size=$4

  debug add_partition "sgdisk -n \"${minor}::+${size}\" -t \"${minor}:${type}\" -c \"${minor}:Linux filesystem\" ${device}"
  sgdisk -n "${minor}::+${size}" -t "${minor}:${type}" -c "${minor}:Linux filesystem" ${device}
  return $?
}
