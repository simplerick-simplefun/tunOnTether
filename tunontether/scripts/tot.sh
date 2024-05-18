#!/system/bin/sh

iprule=$(ip rule | grep -E "from all iif [a-z]*[0-9] lookup (wlan[0-2]|ccmni[0-2])")
dev_tether=$(echo $iprule | sed 's/.*iif //' |  cut -d " " -f1)
dev_tun="tun0"

enable() {
  iptables -N tetherctrl_counters_tun
  iptables -A tetherctrl_counters -j tetherctrl_counters_tun
  iptables -A tetherctrl_counters_tun -i $dev_tether -o $dev_tun -j RETURN
  iptables -A tetherctrl_counters_tun -i $dev_tun -o $dev_tether -j RETURN

  iptables -N tetherctrl_FORWARD_tun
  iptables -D tetherctrl_FORWARD -j DROP
  iptables -A tetherctrl_FORWARD -g tetherctrl_FORWARD_tun
  iptables -A tetherctrl_FORWARD -j DROP

  iptables -A tetherctrl_FORWARD_tun -i $dev_tun -o $dev_tether -m state --state RELATED,ESTABLISHED -g tetherctrl_counters_tun
  iptables -A tetherctrl_FORWARD_tun -i $dev_tether -o $dev_tun -m state --state INVALID -j DROP
  iptables -A tetherctrl_FORWARD_tun -i $dev_tether -o $dev_tun -g tetherctrl_counters_tun


  prt=$(echo $iprule | cut -d ":" -f1)
  prt=$((prt - 1))
  ip rule add priority $prt from all iif $dev_tether table 2022
}

disable() {
  iptables -D tetherctrl_counters -j tetherctrl_counters_tun
  iptables -F tetherctrl_counters_tun
  iptables -D tetherctrl_FORWARD -g tetherctrl_FORWARD_tun
  iptables -F tetherctrl_FORWARD_tun
  sleep 1s
  iptables -X tetherctrl_counters_tun
  iptables -X tetherctrl_FORWARD_tun
  
  prt=$(ip rule | grep "from all iif $dev_tether lookup 2022" | cut -d ":" -f1)
  ip rule del priority $prt
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
