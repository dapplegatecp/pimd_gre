#!/bin/sh
set -e
gre_key=${GRE_KEY:-0}
gre_local=${GRE_LOCAL:-172.16.0.2/24}
gre_remote=${GRE_REMOTE:-172.16.0.1/24}
gre_gateway=${GRE_GATEWAY:-0.0.0.0}
pim_rp=${PIM_RP:-192.168.127.1}

# Create a GRE tunnel
ip link add g0 type gre key $gre_key remote $gre_gateway
ip link set g0 multicast on
ip addr add $gre_local peer $gre_remote dev g0
ip link set g0 up
ip route add $pim_rp/32 dev g0

cat <<EOF > /etc/pimd.conf
phyint g0 enable igmpv3
phyint eth0 enable igmpv3
rp-address $pim_rp 224.0.0.0/4
EOF

exec "$@"