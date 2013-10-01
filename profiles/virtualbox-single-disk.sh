. profiles/common/base.sh
. profiles/common/virtualbox.sh

part sda 1 fd00

format /dev/sda1 ext3

mountfs /dev/sda1 ext3 /

net eth0 dhcp

shutdown
