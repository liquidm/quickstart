. profiles/common/base.sh

net eth0 dhcp

part sda 1 fd00

format /dev/sda1 ext4

mountfs /dev/sda1 ext4 /
