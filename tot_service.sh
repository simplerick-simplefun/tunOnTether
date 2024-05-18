#!/sbin/sh

module_dir="/data/adb/modules/hs-tun"

[ -n "$(magisk -v | grep lite)" ] && module_dir=/data/adb/lite_modules/hs-tun

scripts_dir="/data/adb/tunontether/scripts"

inotifyd ${scripts_dir}/box.inotify ${module_dir} > /dev/null 2>&1 &