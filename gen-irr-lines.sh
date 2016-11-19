#!/bin/bash

#inputfile=as206946-peerings.txt
if [ $# -ne 1 ]; then
    echo "Usage: $0 ASN (e. g. $0 206946)"
    exit 1
fi
inputfile="as${1}-peerings.txt"
if [ ! -e ${inputfile} ]; then
    echo "Need peering description for AS${1} in ${inputfile}."
    exit 1
fi

whois -h whois.ripe.net as${1} >/tmp/$$-asn.out

awk </tmp/$$-asn.out -v ASN=${1} '
BEGIN{
  doit=0;
}

{
  if(index($1, "aut-num:"))
    doit=1;
  if(index($0, "+---------------") || index($0, "---8<--- IRR data"))
    doit=0;
  if(doit==1) {
    if(NF==0)
      exit(1);
    else
      outline[++numlines]=$0;
  }
}

END {
  for(i=1; i<=numlines; i++)
    printf("%s\n", outline[i]);
}'

if [ $? -ne 0 ]; then
    echo "$0: parse error on aut-num: object." >/dev/stderr
    exit 1
fi

awk < ${inputfile} '/^#/ {next};
NF==6 {
  myas=$1; peeras=$2; ins=$3; outs=$4; location=$5; tag=$6;
  if(tag=="upstream") {
    upstr_peer[++upstreams]=peeras;
    upstr_in[upstreams]=ins;
    upstr_out[upstreams]=outs;
  }
  if(tag=="downstream") {
    dnstr_peer[++downstreams]=peeras;
    dnstr_in[downstreams]=ins;
    dnstr_out[downstreams]=outs;
  }
  if(tag=="peering") {
    peer_peer[++peers]=peeras;
    peer_in[peers]=ins;
    peer_out[peers]=outs;
  }
}
END {
  printf("remarks: ---8<--- IRR data\n");
  if(upstreams>0) {
    printf("remarks: +---------------\nremarks: | Upstreams\nremarks: +---------------\n");
    for(i=1; i<=upstreams; i++) {
      lnks[upstr_peer[i]]++;
      if(lnks[upstr_peer[i]]==1) {
        printf("mp-import: afi ipv6.unicast from AS%s accept %s\nmp-export: afi ipv6.unicast to AS%s announce %s\n", upstr_peer[i], upstr_in[i], upstr_peer[i], upstr_out[i]);
        printf("import: from AS%s accept %s\nexport: to AS%s announce %s\n", upstr_peer[i], upstr_in[i], upstr_peer[i], upstr_out[i]);
      }
    }
  }
  if(downstreams>0) {
    printf("remarks: +---------------\nremarks: | Downstreams\nremarks: +---------------\n");
    for(i=1; i<=downstreams; i++) {
      lnks[dnstr_peer[i]]++;
      if(lnks[dnstr_peer[i]]==1) {
        printf("mp-import: afi ipv6.unicast from AS%s accept %s\nmp-export: afi ipv6.unicast to AS%s announce %s\n", dnstr_peer[i], dnstr_in[i], dnstr_peer[i], dnstr_out[i]);
        printf("import: from AS%s accept %s\nexport: to AS%s announce %s\n", dnstr_peer[i], dnstr_in[i], dnstr_peer[i], dnstr_out[i]);
      }
    }
  }
  if(peers>0) {
    printf("remarks: +---------------\nremarks: | Peerings\nremarks: +---------------\n");
    for(i=1; i<=peers; i++) {
      lnks[peer_peer[i]]++;
      if(lnks[peer_peer[i]]==1) {
        printf("mp-import: afi ipv6.unicast from AS%s accept %s\nmp-export: afi ipv6.unicast to AS%s announce %s\n", peer_peer[i], peer_in[i], peer_peer[i], peer_out[i]);
        printf("import: from AS%s accept %s\nexport: to AS%s announce %s\n", peer_peer[i], peer_in[i], peer_peer[i], peer_out[i]);
      }
    }
  }
  printf("remarks: --->8--- IRR data\n");
}'

awk </tmp/$$-asn.out '
BEGIN{
  doit=0;
}

{
  if(index($0, "--->8--- IRR data")) {
    doit=1;
    next;
  }
  if(doit==0 && index($0, "For information on")) {
    doit=1;
  }
  if(doit==1)
    print $0;
  if(NF==0)
    doit=0;
}'

/bin/rm /tmp/$$-asn.out
