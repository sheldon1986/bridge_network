#!/bin/bash

echo "please insert ip for make bridge network"
read IP

IF=`ip addr |grep $IP |awk -F " " '{print $NF}'`
GW=`netstat -rn  |grep $IF |awk -F " " '{print $2}' |grep -v 0.0.0.0`
RBGW=`cat /tmp/GW.txt`
RBIF=`cat /tmp/IF.txt`
bridge=br2
bridge_status=`brctl show |grep br2 |wc -l`

if ! ping $GW -c 1 ;then
	echo "error"
else
        echo "Bridge network configuration"
	echo $IF > /tmp/IF.txt
        modprobe bridge;
        brctl addbr $bridge;
        brctl addif $bridge $IF;
        ifconfig $IF 0.0.0.0;
        ifconfig $bridge $IP up;
        route add -net default gw $GW
	echo $GW > /tmp/GW.txt
fi	
	if ping $GW -c 1 ;then
		echo "complete"
	else if [[ $bridge_status == 1 ]];then
	        echo "Bridge Configuration rollback"
        	ip link set $bridge down;
     	        brctl delbr $bridge;
        	ifconfig $RBIF $IP
		route add -net default gw $RBGW
	else
		exit 1
	fi
fi

