#!/bin/sh
set -e
sleep 20
pim_rp=${PIM_RP:-192.168.127.1}

pim_eth0=${PIM_ETH0:-eth0}
pim_eth1=${PIM_ETH1:-eth1}

gre_key=${GRE_KEY:-0}
gre_local=${GRE_LOCAL:-172.16.0.2/24}
gre_remote=${GRE_REMOTE:-172.16.0.1}
gre_gateway=${GRE_GATEWAY:-0.0.0.0}
pim_gw=${PIM_GW:-${gre_remote}}

# Create a GRE tunnel
ip link add g0 type gre key $gre_key remote $gre_gateway ttl 64
ip link set g0 multicast on
ip addr add $gre_local dev g0
ip link set g0 up

ip route add $pim_rp/32 via $pim_gw

cat <<EOF > /etc/pimd.conf
phyint g0 enable igmpv3
phyint $pim_eth0 enable igmpv3
phyint $pim_eth1 enable igmpv3
rp-address $pim_rp 224.0.0.0/4
EOF

exec "$@"