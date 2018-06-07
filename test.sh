#!/bin/bash

IP=$1
if [[ $IP = "" ]];then
	echo "please insert ip for make bridge network"
	read IP
fi

if [[ $(cat /etc/*-release 2> /dev/null | head -1 |grep Ubuntu) != "" ]];then
	Installer="apt-get"
elif [[ $(cat /etc/*-release 2> /dev/null | head -1 |grep CentOS) != "" ]];then
	Installer="yum"
fi

package_checker(){
cmd_name=$1
package_name=$2
	if [[ $(which $cmd_name) = "" ]];then
		$Installer install -y $package_name
		echo " = $package_name package has been installed"
	fi
}	

## Make sure the command & package install check
#package_checker ip ntmgt
package_checker netstat net-tools
package_checker brctl bridge-utils
#package_checker modprobe kvm

interface=`ip addr |grep $IP |awk -F " " '{print $NF}'`
GW=`netstat -rn  |grep $interface |awk -F " " '{print $2}' |grep -v 0.0.0.0`
RBGW=`cat /tmp/GW.txt`
bridge=metrom_br
bridge_status=`brctl show |grep $bridge |wc -l`
gw_chk_file="/tmp/GW.txt"
interface_addr_file="/tmp/interface.txt"


if ! ping $GW -c 1 ;then
	echo "error"
else
        echo "Bridge network configuration"
	echo "$interface" > $interface_addr_file
        modprobe bridge;
        brctl addbr $bridge;
        brctl addif $bridge $interface;
        ifconfig $interface 0.0.0.0;
        ifconfig $bridge $IP up;
        route add -net default gw $GW
	echo "$GW" > $gw_chk_file
fi


if ping $GW -c 1 ;then
	echo "complete"
elif [[ $bridge_status == 1 ]];then
        echo "Bridge Configuration rollback"
	ip link set $bridge down;
        brctl delbr $bridge;
	ifconfig $RBinterface $IP
	route add -net default gw $RBGW
else
	exit 1
fi
