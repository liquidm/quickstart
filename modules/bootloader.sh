get_boot_and_root() {
  for mount in ${localmounts}; do
    local devnode=$(echo ${mount} | cut -d ':' -f1)
    local mountpoint=$(echo ${mount} | cut -d ':' -f3)
    if [ "${mountpoint}" = "/" ]; then
      local root="${devnode}"
    elif [ "${mountpoint}" = "/boot" -o "${mountpoint}" = "/boot/" ]; then
      local boot="${devnode}"
    fi
  done
  if [ -z "${boot}" ]; then
    local boot="${root}"
  fi
  echo "${boot}|${root}"
}

sanity_check_config_bootloader() {
  debug sanity_check_config_bootloader "no arch-specific bootloader config sanity check function"
}

local arch=$(get_arch)
if [ -f "modules/bootloader_${arch}.sh" ]; then
  debug bootloader.sh "loading arch-specific module bootloader_${arch}.sh"
  import bootloader_${arch}
fi
