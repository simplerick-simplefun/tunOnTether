#!/sbin/sh

module_dir="/data/adb/modules/hs-tun"

[ -n "$(magisk -v | grep lite)" ] && module_dir=/data/adb/lite_modules/hs-tun

scripts_dir="/data/adb/tunontether/scripts"

(
until [ $(getprop sys.boot_completed) -eq 1 ] ; do
  sleep 3
done
touch ${module_dir}/disable
)&

inotifyd ${scripts_dir}/tot.inotify ${module_dir} > /dev/null 2>&1 &