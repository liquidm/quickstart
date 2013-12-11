. profiles/generic-two-disk-md.sh

part sdc 1 83
part sdd 1 83
part sde 1 83
part sdf 1 83
part sdg 1 83

format /dev/sdc1 xfs
format /dev/sdd1 xfs
format /dev/sde1 xfs
format /dev/sdf1 xfs
format /dev/sdg1 xfs

mountfs /dev/sdc1 xfs /var/app/kafka/storage/c
mountfs /dev/sdd1 xfs /var/app/kafka/storage/d
mountfs /dev/sde1 xfs /var/app/kafka/storage/e
mountfs /dev/sdf1 xfs /var/app/kafka/storage/f
mountfs /dev/sdg1 xfs /var/app/kafka/storage/g
