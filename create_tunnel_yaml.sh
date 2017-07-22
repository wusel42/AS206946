#!/usr/bin/env bash
#
# Build for interactive use, i. e. set PATH accordingly if run via cron
#
# To facilitate "virtual remote execution" ;), enter target hostname as $2
#
# To keep work down, we now need the AS number (ASN, just the number) as
# first argument.
#
# E. g.: ./create_tunnel_yaml.sh 206813 [hostname] [-legacy]
#
# The option "-legacy" makes this script use "tunprefix-" in front of tunnel
# names; the new default is prefixing numbered tunnels (used for routing)
# with "T", unnumbered ones (used for bridging) with "E".
#
# Example: old: "ffgt-bgp-fks01", new "Tbgpfks01".
#
# This was done to unclutter configs and status listings.

if [ $# -lt 1 -o $# -gt 3 ]; then
    echo "Usage: $0 ASN [hostname] [-legacy]"
    exit 1
fi

ASN=$1
legacy=0
uname="`uname -n`"
if [ $# -eq 2 ]; then
  if [ "$2" == "-legacy" ]; then
    legacy=1
  else
    uname="$2"
    (>&2 echo "Using ${uname} as local hostname")
  fi
fi

if [ $# -eq 3 ]; then
  if [ "$3" == "-legacy" ]; then
    legacy=1
  else
    echo "Usage: $0 ASN [hostname] [-legacy] ($3 is an unknown flag)"
    exit 1
  fi
fi

if [ ! -e "as${ASN}-tunnel.txt" -o ! -e "as${ASN}-tunnel-mapping.sed" ]; then
  echo "$0: Error, missing control files (as${ASN}-tunnel.txt and/or as${ASN}-tunnel-mapping.sed)."
  exit 1
fi

# This is a bit messy. AS206946 bgp host are named CCTLD#.dn42.uu.org
# they get mapped to xx##-names (or, actually, anything except bgp##)
# for the tun-ip.sh-script, as we want to peer with our Freifunk BGP
# hosts as well (which is where tun-ip-sh originates from). Thus, if
# name is ^bgp, we must lookup $name.4830.org to find the ipv4
# tunnelendpoint, but we must use the mapped name for the invocation
# of tun-ip.sh ...
#
# Format of as206946-tunnel.txt is link-spec <space> tunnel-type, e. g.
#
# de3:uk2 gre
# de3:us1 l2tp
# de3:gut1 ovpn
if [ ${ASN} -eq 206813 ]; then
  dnssuffix="4830.org"
  tunprefix="ffgt"
elif [ ${ASN} -eq 206946 ]; then
  dnssuffix="dn42.uu.org"
  tunprefix="uu"
else
  echo "$0: Error, ASN ${ASN} unknown, please fix the script!"
  exit 1
fi

# Make sure we don't get surprised by I8N ;-)
LANG=C
export LANG


for i in `sed -e 's/ /;/g' <as${ASN}-tunnel.txt | grep ${uname}`
do
  linkspec="`echo $i | cut -d ";" -f 1`"
  TYPE="`echo $i | cut -d ";" -f 2`"
  LHS="`echo ${linkspec} | awk '{split($1, lp, ":"); print lp[1];}'`"
  RHS="`echo ${linkspec} | awk '{split($1, lp, ":"); print lp[2];}'`"
  LHSshort="`echo ${linkspec} | awk '{gsub("-", "", $1); split($1, lp, ":"); print lp[1];}'`"
  RHSshort="`echo ${linkspec} | awk '{gsub("-", "", $1); split($1, lp, ":"); print lp[2];}'`"
  LHTMPNAME="`echo ${linkspec} | cut -d " " -f 1 | sed -f ./as${ASN}-tunnel-mapping.sed | awk '{split($1, lp, ":"); print lp[1];}'`"
  RHTMPNAME="`echo ${linkspec} | cut -d " " -f 1 | sed -f ./as${ASN}-tunnel-mapping.sed | awk '{split($1, lp, ":"); print lp[2];}'`"
  tunprefix="${tunprefix}-"

  domain="${dnssuffix}"
  LHSTUNNAME="$LHS"
  echo "$LHS" | grep bgp 2>&1 >/dev/null && domain="4830.org"
  if [ "$domain" == "4830.org" ]; then tunprefix="ffgt"; fi
  if [ $legacy -eq 0 ]; then
    tunprefix="T"
    if [ "${TYPE}" = "l2tp-eth" ]; then
      tunprefix="E"
    fi
    LHSTUNNAME="$LHSshort"
  fi
  LHSIP="`host ${LHS}.${domain} | awk '/has address/ {print $NF;}'`"
  LHS6IP="`host ${LHS}.${domain} | awk '/has IPv6 address/ {print $NF;}'`"

  domain="${dnssuffix}"
  RHSTUNNAME="$RHS"
  echo "$RHS" | grep bgp 2>&1 >/dev/null && domain="4830.org"
  if [ "$domain" == "4830.org" ]; then tunprefix="ffgt"; fi
  if [ $legacy -eq 0 ]; then
    tunprefix="T"
    if [ "${TYPE}" = "l2tp-eth" ]; then
      tunprefix="E"
    fi
  RHSTUNNAME="$RHSshort"
  fi
  RHSIP="`host ${RHS}.${domain} | awk '/has address/ {print $NF;}'`"
  RHS6IP="`host ${RHS}.${domain} | awk '/has IPv6 address/ {print $NF;}'`"

  if [ "$LHS" = "$uname" ]; then
    echo "${tunprefix}${RHSTUNNAME}:"
    echo "  pub4src: \"$LHSIP\""
    echo "  pub4dst: \"$RHSIP\""
    if [ "${TYPE}" = "lan" ]; then
      echo "  ipv6src: \"${LHS6IP}\""
      echo "  ipv6dst: \"${RHS6IP}\""
      echo "  ipv4src: \"${LHSIP}\""
      echo "  ipv4dst: \"${RHSIP}\""
    elif [ "${TYPE}" = "l2tp-ll" ]; then
      ./tun-ip.sh $LHTMPNAME:$RHTMPNAME linklocal | awk '{gsub("IP", "ip", $1); gsub(":", "src:", $1); printf("  %s \"%s\"\n", $1, $2);}'
      ./tun-ip.sh $RHTMPNAME:$LHTMPNAME linklocal | awk '{gsub("IP", "ip", $1); gsub(":", "dst:", $1); printf("  %s \"%s\"\n", $1, $2);}'
    else
      ./tun-ip.sh $LHTMPNAME:$RHTMPNAME | awk '{gsub("IP", "ip", $1); gsub(":", "src:", $1); printf("  %s \"%s\"\n", $1, $2);}'
      ./tun-ip.sh $RHTMPNAME:$LHTMPNAME | awk '{gsub("IP", "ip", $1); gsub(":", "dst:", $1); printf("  %s \"%s\"\n", $1, $2);}'
    fi
    echo "  mode: \"${TYPE}\""
  else
    echo "${tunprefix}${LHSTUNNAME}:"
    echo "  pub4src: \"$RHSIP\""
    echo "  pub4dst: \"$LHSIP\""
    if [ "${TYPE}" = "lan" ]; then
      echo "  ipv6src: \"${RHS6IP}\""
      echo "  ipv6dst: \"${LHS6IP}\""
      echo "  ipv4src: \"${RHSIP}\""
      echo "  ipv4dst: \"${LHSIP}\""
    elif [ "${TYPE}" = "l2tp-ll" ]; then
      ./tun-ip.sh $LHTMPNAME:$RHTMPNAME linklocal | awk '{gsub("IP", "ip", $1); gsub(":", "dst:", $1); printf("  %s \"%s\"\n", $1, $2);}'
      ./tun-ip.sh $RHTMPNAME:$LHTMPNAME linklocal | awk '{gsub("IP", "ip", $1); gsub(":", "src:", $1); printf("  %s \"%s\"\n", $1, $2);}'
    else
      ./tun-ip.sh $LHTMPNAME:$RHTMPNAME | awk '{gsub("IP", "ip", $1); gsub(":", "dst:", $1); printf("  %s \"%s\"\n", $1, $2);}'
      ./tun-ip.sh $RHTMPNAME:$LHTMPNAME | awk '{gsub("IP", "ip", $1); gsub(":", "src:", $1); printf("  %s \"%s\"\n", $1, $2);}'
    fi
    echo "  mode: \"${TYPE}\""
  fi
  echo
done | sed -e 's%/64%%g'> tunnel.yaml
