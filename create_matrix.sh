#!/usr/bin/env bash
#
# Build for interactive use, i. e. set PATH accordingly if run via cron
#
# Read as206946-hosts.txt and generate a matrix of connections.

awk < as206946-hosts.txt >as206946-tunnel.txt '{host[++num]=$1;} END {for(i=1; i<=num; i++) { for(j=i; j<=num; j++) {if(host[i] != host[j]) printf("%s-%s l2tp\n", host[i], host[j]);}}}'
