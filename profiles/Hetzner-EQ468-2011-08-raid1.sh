# Hetzner EQ4/6/8 profile with Software RAID-1
# see http://www.hetzner.de/hosting/produktmatrix/rootserver-produktmatrix-eq

. profiles/Hetzner-EQ468-2011-08.sh

mdraid md2 --metadata=0.90 --level=1 --raid-devices=2 /dev/sda2 /dev/sdb2
