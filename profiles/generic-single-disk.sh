. profiles/common/base.sh

part sda 1 fd00

format /dev/sda1 ext4

mountfs /dev/sda1 ext4 /
