#!/system/bin/sh

service_dir="/data/adb/service.d"
if [ "$KSU" = true ] && [ "$KSU_VER_CODE" -lt 10683 ] ; then
  service_dir="/data/adb/ksu/service.d"




rm -f $service_dir/tot_service.sh
