unpack_tarball() {
  local file=$1
  local dest=$2
  local preserve=$3

  tar_flags="x"

  if [ "$preserve" = "1" ]; then
    tar_flags="${tar_flags}p"
  fi

  extension=$(echo "$file" | sed -e 's:^.*\.\([^.]\+\)$:\1:')
  case $extension in
    gz)
      tar_flags="${tar_flags}z"
      spawn "tar -C ${dest} -${tar_flags} -f ${file}"
      ;;
    bz2)
      tar_flags="${tar_flags}j"
      spawn "tar -C ${dest} -${tar_flags} -f ${file}"
      ;;
    lz*|xz*)
      tar_flags="${tar_flags}l"
      spawn "tar -C ${dest} -${tar_flags} -f ${file}"
      ;;
    squashfs)
      mkdir -p ${dest}/squashfs
      mount ${file} ${dest}/squashfs
      rsync -azvP ${dest}/squashfs ${dest}
      umount ${dest}/squashfs
      rmdir ${dest}/squashfs
      ;;
  esac

  return $?
}
