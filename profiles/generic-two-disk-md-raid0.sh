. profiles/generic-two-disk-md.sh

mdraid md2 --metadata=0.90 --level=0 --raid-devices=2 /dev/sda2 /dev/sdb2
