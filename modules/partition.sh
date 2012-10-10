format_devnode() {
  local device=$1
  local partition=$1
  local devnode=""

  echo "${device}" | grep -q '[0-9]$'
  if [ $? = "0" ]; then
    devnode="${device}p${partition}"
  else
    devnode="${device}${partition}"
  fi
  echo "${devnode}"
}

gdisk_command() {
  local device=$1
  local cmd=$2

  debug gdisk_command "running gdisk command '${cmd}' on device ${device}"
  spawn "echo -en '${cmd}\nw\ny\n' | gdisk ${device}"
  local ret=$?

  debug gdisk_command "sleeping 3 seconds after gdisk to prevent EBUSY from previous run"
  sleep 3

  return ${ret}
}

local arch=$(get_arch)
if [ -f "modules/partition_${arch}.sh" ]; then
  debug partition.sh "loading arch-specific module partition_${arch}.sh"
  import partition_${arch}
fi
