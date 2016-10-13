#!/usr/bin/env bash
#
# Build for interactive use, i. e. set PATH accordingly if run via cron
#
# To facilitate "virtual remote execution" ;), enter target hostname as $1
#
# Usage: create_dns.sh as206946.net 198.19 2a07:a907:50c:f
#
# Requires: sipcalc

if [ $# -eq 3 ]; then
  domain="$1"
  ipv4base="$2"
  ipv6base="$3"
else
  (>&2 echo "Usage: $0 domain ipv4-base ipv6-base")
  exit 1
fi

# Make sure we don't get surprised by I8N ;-)
LANG=C
export LANG

rev6domain="`sipcalc -r ${ipv6base}000:: | grep ^0 | awk '{f=split($1, addr, "."); for(i=20; i<f; i++) printf("%s.", addr[i]); printf("\n");}' | awk '{gsub("arpa.", "arpa"); print $0;}'`"
rev4domain="`echo \"${ipv4base}\" | awk 'BEGIN{FS=".";} {printf("%s.%s.in-addr.arpa\n", $2, $1);}'`"

cat /dev/null >${domain}.inc
cat /dev/null >${rev4domain}.inc
cat /dev/null >${rev6domain}.inc

for i in `cat as206946-tunnel.txt`
do
  LHS="`echo $i | awk '{split($1, lp, "-"); print lp[1];}'`"
  RHS="`echo $i | awk '{split($1, lp, "-"); print lp[2];}'`"
  LHTMPNAME="`echo $i | sed -f ./as206946-tunnel-mapping.sed | awk '{split($1, lp, "-"); print lp[1];}'`"
  RHTMPNAME="`echo $i | sed -f ./as206946-tunnel-mapping.sed | awk '{split($1, lp, "-"); print lp[2];}'`"
  ./tun-ip.sh $LHTMPNAME-$RHTMPNAME > /tmp/$$.tmp
  IP4="`grep </tmp/$$.tmp IPv4: | cut -d ' ' -f 2`"
  IP6="`grep </tmp/$$.tmp IPv6: | cut -d ' ' -f 2 | sed -e 's%/64%%g'`"
  echo "${LHS}-${RHS} IN A ${IP4}" >> ${domain}.inc
  echo "${LHS}-${RHS} IN AAAA ${IP6}" >> ${domain}.inc
  echo "${IP4}" | awk -v tunnel="${LHS}-${RHS}.${domain}" '{split($1, addr, "."); printf("%s.%s.%s.%s.in-addr.arpa. IN PTR %s.\n", addr[4], addr[3], addr[2], addr[1], tunnel);}' >> ${rev4domain}.inc
  sipcalc -r "${IP6}" | grep ip6.arpa | tail -1 | awk '{f=split($1, addr, "."); for(i=1; i<19; i++) printf("%s.", addr[i]); printf("%s\n", addr[i]);}' | awk -v tunnel="${LHS}-${RHS}.${domain}" '{printf("%s IN PTR %s.\n", $1, tunnel);}' >> ${rev6domain}.inc

  ./tun-ip.sh $RHTMPNAME-$LHTMPNAME > /tmp/$$.tmp
  IP4="`grep </tmp/$$.tmp IPv4: | cut -d ' ' -f 2`"
  IP6="`grep </tmp/$$.tmp IPv6: | cut -d ' ' -f 2 | sed -e 's%/64%%g'`"
  echo "${RHS}-${LHS} IN A ${IP4}" >> ${domain}.inc
  echo "${RHS}-${LHS} IN AAAA ${IP6}" >> ${domain}.inc
  echo "${IP4}" | awk -v tunnel="${RHS}-${LHS}.${domain}" '{split($1, addr, "."); printf("%s.%s.%s.%s.in-addr.arpa. IN PTR %s.\n", addr[4], addr[3], addr[2], addr[1], tunnel);}' >> ${rev4domain}.inc
  sipcalc -r "${IP6}" | grep ip6.arpa | tail -1 | awk '{f=split($1, addr, "."); for(i=1; i<19; i++) printf("%s.", addr[i]); printf("%s\n", addr[i]);}' | awk -v tunnel="${RHS}-${LHS}.${domain}" '{printf("%s IN PTR %s.\n", $1, tunnel);}' >> ${rev6domain}.inc
done
rm /tmp/$$.tmp