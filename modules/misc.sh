get_arch() {
  ${linux32} uname -m | sed -e 's:i[3-6]86:x86:' -e 's:x86_64:amd64:'
}

unpack_tarball() {
  local file=$1
  local dest=$2
  local preserve=$3

  tar_flags="xv"

  if [ "$preserve" = "1" ]; then
    tar_flags="${tar_flags}p"
  fi

  extension=$(echo "$file" | sed -e 's:^.*\.\([^.]\+\)$:\1:')
  case $extension in
    gz)
      tar_flags="${tar_flags}z"
      ;;
    bz2)
      tar_flags="${tar_flags}j"
      ;;
    lz*|xz*)
      tar_flags="${tar_flags}l"
      ;;
  esac

  spawn "tar -C ${dest} -${tar_flags} -f ${file}"
  return $?
}
