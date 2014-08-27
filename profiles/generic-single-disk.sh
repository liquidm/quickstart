. profiles/common/base.sh

net eth0 current

part sda 1 fd00

format /dev/sda1 ext4

mountfs /dev/sda1 ext4 /
