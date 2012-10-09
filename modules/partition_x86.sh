create_disklabel() {
  local device=$1

  debug create_disklabel "creating new gpt disklabel"
  gdisk_command ${device} "o\ny"

  # add bios boot partition for good measure
  for device in ${bootloader_install_device}; do
    gdisk_command ${device} "n\n128\n-32M\n\nef02\n"
  done

  return $?
}

add_partition() {
  local device=$1
  local minor=$2
  local type=$3
  local size=$4

  gdisk_command ${device} "n\n${minor}\n\n+${size}\n${type}\n"
  return $?
}
