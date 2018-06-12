#!/bin/bash

## Insert IP for make bridge
IP=$1
if [[ $IP = "" ]];then
	echo "please insert ip for make bridge network"
	read IP
fi

## check OS for install packages
if [[ $(cat /etc/*-release 2> /dev/null | head -1 |grep Ubuntu) != "" ]];then
	Installer="apt-get"
else
	Installer="yum"
fi

## check packages
package_checker(){
cmd_name=$1
package_name=$2
	if [[ $(which $cmd_name) = "" ]];then
		$Installer install -y $package_name
		echo " = $package_name package has been installed"
	fi
}	

## Make sure the command & package install check
package_checker netstat net-tools
package_checker brctl bridge-utils

interface=`ip addr |grep $IP |awk -F " " '{print $NF}'`
GW=`netstat -rn  |grep $interface |awk -F " " '{print $2}' |grep -v 0.0.0.0`
#GW=192.0.0.3
bridge=br-metrom
bridge_chk=`brctl show |grep $bridge |wc -l`
gw_chk_file="/tmp/gateway.txt"
interface_addr_file="/tmp/interface.txt"
ip_route=`ip route |grep $interface |grep -v default |awk '{print $1}' |awk -F "/" '{print $2}'`


cdr2mask ()
{
   # Number of args to shift, 255..255, first non-255 byte, zeroes
   set -- $(( 5 - ($1 / 8) )) 255 255 255 255 $(( (255 << (8 - ($1 % 8))) & 255 )) 0 0 0
   [ $1 -gt 1 ] && shift $1 || shift
   echo ${1-0}.${2-0}.${3-0}.${4-0}
}

NM=`cdr2mask $ip_route`


if ! ping $GW -c 1 ;then
	echo "error"
else
        echo "Bridge network configuration"
	echo "$interface" > $interface_addr_file
        modprobe bridge
        brctl addbr $bridge
        brctl addif $bridge $interface
        ifconfig $interface 0.0.0.0
        ifconfig $bridge $IP up netmask $NM
        route add -net default gw $GW
	echo "$GW" > $gw_chk_file
fi


if ping $GW -c 1 ;then
	echo "complete"
elif [[ $bridge_chk == 1 ]];then
        echo "Bridge Configuration rollback"
	ip link set $bridge down
        brctl delbr $bridge
	ifconfig $(cat $interface_addr_file) $IP netmask $NM
	route add -net default gw $(cat $gw_chk_file)
else
	exit 1
fi
