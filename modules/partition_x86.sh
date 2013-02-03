create_disklabel() {
  local device=$1

  debug create_disklabel "creating new gpt disklabel"
  gdisk_command ${device} "o\ny"

  # add bios boot partition for good measure
  gdisk_command ${device} "n\n128\n-32M\n\nef02\n"

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

convert_to_mbr() {
  local device=$1
  gdisk_command ${device} "r\ng"

  partprobe

  debug gdisk_command "sleeping 3 seconds after partprobe"
  sleep 3
}
