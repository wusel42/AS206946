# AS206946
Stuff for maintaining my and FFGT's Autonomous Systems

----------

Files as*-peerings.txt: these describe with which other ASNs an ASN will exchange which ASes/AS-Sets. Used for "./gen-irr-lines.sh".

Example:
```
wusel@ysabell:/data/wusel/AS206946$ cat as206813-peerings.txt 
# my-as peer-AS in out my-host tag
206813 206946 ANY AS-FFGT de3 upstream
206813 206740 AS206740 AS-FFGT de3 peering
206813 201701 ANY AS-FFGT bgp2 upstream
206813 44194 AS44194 AS-FFGT bgp2 peering
206813 49009 AS49009 AS-FFGT bgp2 peering
```
---------

./gen-irr-lines.sh ASN

Fetch AS info from (RIPE) whois DB, cut at "---..--- IRR data" and fill in current info based on "as$ASN-peerings.txt" file.

Example:
```
wusel@ysabell:/data/wusel/AS206946$ ./gen-irr-lines.sh 206813
aut-num:        AS206813
as-name:        AS4830org
org:            ORG-AA1637-RIPE
sponsoring-org: ORG-SL561-RIPE
admin-c:        TA5645-RIPE
tech-c:         TA5645-RIPE
remarks: ---8<--- IRR data
remarks: +---------------
remarks: | Upstreams
remarks: +---------------
mp-import: afi ipv6.unicast from AS206946 accept ANY
mp-export: afi ipv6.unicast to AS206946 announce AS-FFGT
import: from AS206946 accept ANY
export: to AS206946 announce AS-FFGT
mp-import: afi ipv6.unicast from AS201701 accept ANY
mp-export: afi ipv6.unicast to AS201701 announce AS-FFGT
import: from AS201701 accept ANY
export: to AS201701 announce AS-FFGT
remarks: +---------------
remarks: | Peerings
remarks: +---------------
mp-import: afi ipv6.unicast from AS206740 accept AS206740
mp-export: afi ipv6.unicast to AS206740 announce AS-FFGT
import: from AS206740 accept AS206740
export: to AS206740 announce AS-FFGT
mp-import: afi ipv6.unicast from AS44194 accept AS44194
mp-export: afi ipv6.unicast to AS44194 announce AS-FFGT
import: from AS44194 accept AS44194
export: to AS44194 announce AS-FFGT
mp-import: afi ipv6.unicast from AS49009 accept AS49009
mp-export: afi ipv6.unicast to AS49009 announce AS-FFGT
import: from AS49009 accept AS49009
export: to AS49009 announce AS-FFGT
remarks: --->8--- IRR data
remarks:        For information on "status:" attribute read https://www.ripe.net/data-tools/db/faq/faq-status-values-legacy-resources
status:         ASSIGNED
mnt-by:         RIPE-NCC-END-MNT
mnt-by:         MNT-WUSEL
mnt-by:         FROSTY-MNT
mnt-routes:     MNT-WUSEL
mnt-routes:     FROSTY-MNT
created:        2016-11-01T13:15:31Z
last-modified:  2016-11-15T23:25:31Z
source:         RIPE
```

This output can e. g. cut&pasted into the RIPE DB webinterface. (I'm no LIR, that's how I interact with RIPE and IRR data.)

----------

