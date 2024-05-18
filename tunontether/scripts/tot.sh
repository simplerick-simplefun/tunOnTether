#!/system/bin/sh

iprule_prt_file="/data/adb/tunontether/run/iprule_prt"
disable_file="/data/adb/modules/hs-tun/disable"

iprule_tether=$(ip rule | grep -E "from all iif [a-z]*[0-9] lookup (wlan[0-2]|ccmni[0-2])")
dev_tun=$(ip ro | grep tun | cut -d " " -f3)

tun_table=$(ip rule | grep -E "from all lookup [0-9]+" | cut -d " " -f4)
[ "$iprule_tether" != "" ] && dev_tether=$(echo $iprule_tether | sed 's/.*iif //' |  cut -d " " -f1)

iptables="iptables -w 100"

log() {
  export TZ=Asia/Shanghai
  now=$(date +"[%Y-%m-%d %H:%M:%S %Z]")
  case $1 in
    Info)
      [ -t 1 ] && echo -e "\033[1;32m${now} [Info]: $2\033[0m" || echo "${now} [Info]: $2"
      ;;
    Warn)
      [ -t 1 ] && echo -e "\033[1;33m${now} [Warn]: $2\033[0m" || echo "${now} [Warn]: $2"
      ;;
    Error)
      [ -t 1 ] && echo -e "\033[1;31m${now} [Error]: $2\033[0m" || echo "${now} [Error]: $2"
      ;;
    *)
      [ -t 1 ] && echo -e "\033[1;30m${now} [$1]: $2\033[0m" || echo "${now} [$1]: $2"
      ;;
  esac
}

enable() {
  if [ "$dev_tether" = "" ] ; then
    log Error 'tether/hotspot is not on; cannot find tether/hotspot device' 1>&2
    exit 1
  fi
  if [ "$dev_tun" = "" ] ; then
    log Error 'vpn is not on; cannot find tun device' 1>&2
    exit 2
  fi
  if [ "$tun_table" = "" ] ; then
    log Error 'vpn is not on; cannot find ip route table for tun device' 1>&2
    exit 3
  fi
  
  prt=$(echo $iprule_tether | cut -d ":" -f1)
  prt=$((prt - 1))
  
  log Info "Enabling TunOnTether with following parameters:"
  log Info "dev_tun:$dev_tun tun_table:$tun_table dev_tether:$dev_tether ip_rule_priority:$prt"
  
  ${iptables} -N tetherctrl_counters_tun
  ${iptables} -A tetherctrl_counters -j tetherctrl_counters_tun
  ${iptables} -A tetherctrl_counters_tun -i $dev_tether -o $dev_tun -j RETURN
  ${iptables} -A tetherctrl_counters_tun -i $dev_tun -o $dev_tether -j RETURN

  ${iptables} -N tetherctrl_FORWARD_tun
  ${iptables} -D tetherctrl_FORWARD -j DROP
  ${iptables} -A tetherctrl_FORWARD -g tetherctrl_FORWARD_tun
  ${iptables} -A tetherctrl_FORWARD -j DROP

  ${iptables} -A tetherctrl_FORWARD_tun -i $dev_tun -o $dev_tether -m state --state RELATED,ESTABLISHED -g tetherctrl_counters_tun
  ${iptables} -A tetherctrl_FORWARD_tun -i $dev_tether -o $dev_tun -m state --state INVALID -j DROP
  ${iptables} -A tetherctrl_FORWARD_tun -i $dev_tether -o $dev_tun -g tetherctrl_counters_tun

  ip rule add priority $prt from all iif $dev_tether table $tun_table
  echo $prt > ${iprule_prt_file}
  
  log Info "Tun on tether enabled."
}

disable() {
  ${iptables} -D tetherctrl_counters -j tetherctrl_counters_tun >/dev/null 2>&1
  ${iptables} -F tetherctrl_counters_tun >/dev/null 2>&1
  ${iptables} -D tetherctrl_FORWARD -g tetherctrl_FORWARD_tun >/dev/null 2>&1
  ${iptables} -F tetherctrl_FORWARD_tun >/dev/null 2>&1
  ${iptables} -X tetherctrl_counters_tun >/dev/null 2>&1
  ${iptables} -X tetherctrl_FORWARD_tun >/dev/null 2>&1
  
  #prt=$(ip rule | grep "from all iif $dev_tether lookup $tun_table" | cut -d ":" -f1)
  #[ "$prt" = "" ] && prt=$(cat $iprule_prt_file)
  prt=$(cat $iprule_prt_file) >/dev/null 2>&1
  rm -f $iprule_prt_file
  [ "$prt" != "" ] && ip rule del priority $prt
  log Info "Tun on tether disabled."
}

case "$1" in
enable)
    enable
    ;;
disable)
    disable
    ;;
*)
    echo "$0:  usage:  $0 {enable|disable}"
    ;;
esac
