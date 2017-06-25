#!/bin/sh
#
#
#    1        2         3       4
#  bgp0-15, gw00-gw15, s0-15, xx00-15
#
#
# This script calculates the IPv4 /32 and IPv6 /64 addresses per tunnel.
# There are for "types" of devices defined:
#  - "bgp" servers (sometimes called "supernodes"), that are supposed to
#    talk to other external hosts via BGP, internal one via OSPF.
#  - "gw" servers (Freifunk gateways), which terminate the VPN tunnels
#    from Freifunk nodes and form the batman_adv backbone. They should
#    talk OSPF to bgp hosts nearby.
#  - "s" is short for server, these are e. g. a (unicasted) supplementary
#     servers for e. g. dhcp, statistics, ntp, ...
#  - "xx" is kind of reserved, it's basically "anything else"
#
# The resulting IPs are /32, i. e. point-to-point, ones for IPv4. You need
# a /16 for that, x.x.{1234}{1234}.0/24, will be used.
# For IPv6 it was deciced to stick with the rule of using /64 even for
# point-to-point links. Thus you need to have a /52 ready.
#
# In general, each "type" got a value (bgp: 1, gw: 2, ...), that gets shifted
# 4 bits to the left and combined with the number (which must(!) be between 0
# and 15 - garbage in, garbage out!). Likewise, "bgp", "gw", "s" and "xx" are
# fixed presets; calling the script with an argument of "a0-zz12" would yield
# the same as "uu15-d4"!
#
# If your Naming Scheme differs, you could write a wrapper that maps your
# names 1:1 to those that are expected here ...
#
# Usage expected to be done based on one central list of tunnel connections,
# e. g. hosted in a git repository. A host then should fetch that file and
# "do the needfull" to create the needed tunnels. E. g.:
#
# wusel@ysabell:~$ uname="gw01"; LANG=C ; for i in `cat /tmp/tunnel.txt | grep ${uname}` ; do LHS="`echo $i | cut -d - -f 1`"; RHS="`echo $i | cut -d - -f 2`" ; echo "# Tunnel: $LHS -> $RHS"; LHSIP="`host $LHS.4830.org | awk '/has address/ {print $NF;}'`" ; RHSIP="`host $RHS.4830.org | awk '/has address/ {print $NF;}'`" ; if [ "$LHS" = "$uname" ]; then echo "  pub4src: \"$LHSIP\"" ; echo "  pub4dst: \"$RHSIP\"" ; ./tun-ip.sh $LHS-$RHS | awk '{gsub("IP", "ip", $1); gsub(":", "src:", $1); printf("  %s \"%s\"\n", $1, $2);}' ; ./tun-ip.sh $RHS-$LHS | awk '{gsub("IP", "ip", $1); gsub(":", "dst:", $1); printf("  %s \"%s\"\n", $1, $2);}' ; else echo "  pub4src: \"$RHSIP\"" ; echo "  pub4dst: \"$LHSIP\"" ; ./tun-ip.sh $LHS-$RHS | awk '{gsub("IP", "ip", $1); gsub(":", "dst:", $1); printf("  %s \"%s\"\n", $1, $2);}' ; ./tun-ip.sh $RHS-$LHS | awk '{gsub("IP", "ip", $1); gsub(":", "src:", $1); printf("  %s \"%s\"\n", $1, $2);}' ; fi ; done
# # Tunnel: bgp1 -> gw01
#   pub4src: "5.9.167.222"
#   pub4dst: "192.251.226.114"
#   ipv4dst: "10.234.12.17"
#   ipv6dst: "2a03:2260:117:0111::2/64"
#   ipv4src: "10.234.21.17"
#   ipv6src: "2a03:2260:117:0111::1/64"
# # Tunnel: s3 -> gw01
#   pub4src: "5.9.167.222"
#   pub4dst: "192.251.226.108"
#   ipv4dst: "10.234.32.49"
#   ipv6dst: "2a03:2260:117:0613::1/64"
#   ipv4src: "10.234.23.19"
#   ipv6src: "2a03:2260:117:0613::2/64"
# wusel@ysabell:~$ cat /tmp/tunnel.txt
# bgp1:gw01 type
# bgp2:gw04 type
# s3:gw01 type
# s3:gw04 type
# bgp1:bgp2 type
#
# This way, we can maintain the myriads of tunnels needed centrally and
# create them automatically, locally, per host. The script can be used
# to generate DNS entries as well, just add some more pipes ;)
#
# For FFGT as of this writing, ipv4base is 10.234., ipv6base is 2a03:2260:117:0.
#
# Usage: $0 bgp1-gw04

if [ $# -lt 1 -o $# -gt 2 ]; then
    echo "Usage: $0 bgp1:gw04 [--linklocal]"
    exit 1
fi

v6base=2a07:a907:50c:f

if [ "$2" == "--linklocal" ]; then
    v6base=fe80:deca:fbad:0
fi

echo "$1" | gawk -v ipbase=198.19 '{n=split($1, nodes, ":"); if(n!=2) {printf("Error parsing %s\n", $1); exit;} xval[1]=0; xval[2]=0; for(i=1; i<3; i++) {switch(substr(nodes[i], 1, 1)) {case "b": xval[i]=1; break; case "g": xval[i]=2; break; case "s": xval[i]=3; break; case "x": xval[i]=4; break;}} x=sprintf("%1d%1d", xval[1], xval[2]); for(i=1; i<3; i++) {gsub("^bgp", "", nodes[i]); gsub("^gw", "", nodes[i]); gsub("^s", "", nodes[i]); gsub("^xx", "", nodes[i]);} y=nodes[1]*16+nodes[2]; printf("IPv4: %s.%d.%d\n", ipbase, x, y);}'
echo "$1" | gawk -v ipbase=${v6base} '{n=split($1, nodes, ":"); if(n!=2) {printf("Error parsing %s\n", $1); exit;} xval[1]=0; xval[2]=0; for(i=1; i<3; i++) {switch(substr(nodes[i], 1, 1)) {case "b": xval[i]=1; break; case "g": xval[i]=2; break; case "s": xval[i]=3; break; case "x": xval[i]=4; break;}} if(xval[2]<xval[1]) {tmp=xval[1]; xval[1]=xval[2]; xval[2]=tmp; localip=1;} else {localip=2;} xval[1]--; xval[2]--; x=sprintf("%d", xval[1]*4+xval[2]); for(i=1; i<3; i++) {gsub("^bgp", "", nodes[i]); gsub("^gw", "", nodes[i]); gsub("^s", "", nodes[i]); gsub("^xx", "", nodes[i]);} if(xval[2]==xval[1]) {if(nodes[2]<nodes[1]) {tmp=nodes[1]; nodes[1]=nodes[2]; nodes[2]=tmp; localip=1;} else {localip=2;}} else if(localip==1) {tmp=nodes[1]; nodes[1]=nodes[2]; nodes[2]=tmp;} y=nodes[1]*16+nodes[2]; printf("IPv6: %s%1x%02x::%d/64\n", ipbase, x, y, localip);}'
