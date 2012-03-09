#!/bin/bash

emerge virtualbox-additions
dhcpcd -k eth0

mount /usr/share/virtualbox/*.iso /mnt
/mnt/VBoxLinuxAdditions.run
umount /mnt

emerge -C virtualbox-additions

rm -f /etc/.pwd.lock /etc/resolv.conf /etc/ssh/ssh_host*
rm -f /etc/udev/rules.d/70-persistent-*
rm -rf /var/tmp/* /tmp/* /root/* /var/log/*
rm -rf /var/cache/edb/dep/*
