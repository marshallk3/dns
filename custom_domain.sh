#!/bin/bash
#
# https://github.com/marshallk3/dns
#
# Copyright (c) 2019 MarshallK. Released under the MIT License.

# Detect Debian users running the script with "sh" instead of bash
if readlink /proc/$$/exe | grep -q "dash"; then
	echo "This script needs to be run with bash, not sh"
	exit
fi

# Check if the script is run as root
if [[ "$EUID" -ne 0 ]]; then
	echo "Sorry, you need to run this as root"
	exit
fi


# Predefined variables
#------------------
IP="1.2.3.4"
REVERSE="$(echo $IP | rev).in-addr.arpa"

SOFTWARE="bind9"
PATH="/etc/bind"

ZONE="marshall"
PTR="dns"

#------------------



# Install bind  
apt-get install -y "$SOFTWARE"

# Make directory for zones
mkdir "$PATH"/zones

# Put the following in the named.conf file
echo "

zone \"$ZONE\" {

	type master;
	file \"/etc/bind/zones/$ZONE.db\";

}

zone \"$REVERSE\" {

	type master;
	file \"/etc/bind/zones/$REVERSE.db\";

}

" >> "$PATH"/named.conf.local


# Put the following in the zone.db file
echo "
\$TTL 1h

$ZONE. 	IN 	SOA server.$ZONE. admin.server.$ZONE. (
			2019062001
			28800
			3600
			604800
			38400
)

$ZONE. 	IN 	NS 	server.$ZONE.
server 	IN	A 	$IP
nic 	IN	A 	$IP

" >> "$PATH"/zones/"$ZONE".db



# Put the following in the reverse.db file
echo "
@ 	IN 	SOA server.$ZONE. admin.server.$ZONE. (
			2019062001
			28800
			3600
			604800
			38400
)

		IN 	NS 	server.$ZONE.
$PTR 	IN	PTR 	$ZONE
$PTR 	IN	PTR 	nic.$ZONE

" >> "$PATH"/zones/rev."$REVERSE".db

# Put the following in the resolv.conf file
echo "
search $ZONE
nameserver 1.1.1.1
nameserver 8.8.8.8
" >> /etc/resolv.conf

# Restart the software
/etc/init.d/"$SOFTWARE" restart
