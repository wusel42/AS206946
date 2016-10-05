#!/usr/bin/env bash
#
# Build for interactive use, i. e. set PATH accordingly if run via cron

uname="`uname -n`"

# Make sure we don't get surprised by I8N ;-)
LANG=C
export LANG

# This is a bit messy. AS206946 bgp host are named CCTDL#.dn42.uu.org
# they get mapped to xx##-names for the tun-ip.sh-script, as we want
# to peer with our Freifunk BGP hosts as well (which is where the script
# originates from). Thus, if name is ^bgp, we must lookup $name.4830.org
# to find the ipv4 tunnelendpoint, but we must use the mapped name for
# the invocation of tun-ip.sh ...
for i in `cat as206946-tunnel.txt | grep ${uname}`
do
  LHS="`echo $i | cut -d - -f 1`"
  RHS="`echo $i | cut -d - -f 2`"
  LHTMPNAME="`echo $i | sed -f ./as206946-tunnel-mapping.sed | cut -d - -f 1`"
  RHTMPNAME="`echo $i | sed -f ./as206946-tunnel-mapping.sed | cut -d - -f 2`"
  domain="dn42.uu.org"
  echo "$LHS" | grep bgp 2>&1 >/dev/null && domain="4830.org"
  LHSIP="`host ${LHS}.${domain} | awk '/has address/ {print $NF;}'`"
  domain="dn42.uu.org"
  echo "$RHS" | grep bgp 2>&1 >/dev/null && domain="4830.org"
  RHSIP="`host ${RHS}.${domain} | awk '/has address/ {print $NF;}'`"
  if [ "$LHS" = "$uname" ]; then
    echo "uu-$RHS:"
    echo "  pub4src: \"$LHSIP\""
    echo "  pub4dst: \"$RHSIP\""
    ./tun-ip.sh $LHTMPNAME-$RHTMPNAME | awk '{gsub("IP", "ip", $1); gsub(":", "src:", $1); printf("  %s \"%s\"\n", $1, $2);}'
    ./tun-ip.sh $RHTMPNAME-$LHTMPNAME | awk '{gsub("IP", "ip", $1); gsub(":", "dst:", $1); printf("  %s \"%s\"\n", $1, $2);}'
  else
    echo "uu-$LHS:"
    echo "  pub4src: \"$RHSIP\""
    echo "  pub4dst: \"$LHSIP\""
    ./tun-ip.sh $LHTMPNAME-$RHTMPNAME | awk '{gsub("IP", "ip", $1); gsub(":", "dst:", $1); printf("  %s \"%s\"\n", $1, $2);}'
    ./tun-ip.sh $RHTMPNAME-$LHTMPNAME | awk '{gsub("IP", "ip", $1); gsub(":", "src:", $1); printf("  %s \"%s\"\n", $1, $2);}'
  fi
  echo
done > dn42-tunnel.ymml
