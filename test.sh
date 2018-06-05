#!/bin/bash

echo "please insert ip for make bridge network"

IP=$1
if [[ $IP = "" ]];then
	read IP
fi


Installer=""

package_checker(){
cmd_name=$1
package_name=$2
	if [[ $(which $cmd_name) = "" ]];then
		$Installer install $package_name
		echo " = $package_name package has been installed"
	fi

}	


## Make sure the command & package install check
#package_checker ip ntmgt
#package_checker netstat netstat
#package_checker br_ctl brctl


interface=`ip addr |grep $IP |awk -F " " '{print $NF}'`
GW=`netstat -rn  |grep $interface |awk -F " " '{print $2}' |grep -v 0.0.0.0`
RBGW=`cat /tmp/GW.txt`
RBinterface=`cat /tmp/interface.txt`
bridge=metrom_br
bridge_status=`brctl show |grep $bridge |wc -l`




GW=109.0.0.2

if [[ ! $(ping $GW -c 1) ]];then
	echo "error"
else
        echo "Bridge network configuration"
	echo $interface > /tmp/interface.txt
        modprobe bridge;
        brctl addbr $bridge;
        brctl addif $bridge $interface;
        ifconfig $interface 0.0.0.0;
        ifconfig $bridge $IP up;
        route add -net default gw $GW
	echo $GW > /tmp/GW.txt
fi	
	if [[ $(ping $GW -c 1) ]] ;then
		echo "complete"
	else if [[ $bridge_status == 1 ]];then
	        echo "Bridge Configuration rollback"
        	ip link set $bridge down;
     	        brctl delbr $bridge;
        	ifconfig $RBinterface $IP
		route add -net default gw $RBGW
	else
		exit 1
	fi
fi
