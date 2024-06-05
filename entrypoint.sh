#!/bin/sh
set -e
sleep 20
pim_rp=${PIM_RP:-192.168.127.1}

pim_eth0=${PIM_ETH0:-eth0}

gre_key=${GRE_KEY:-0}
gre_local=${GRE_LOCAL:-172.16.0.2/24}
gre_remote=${GRE_REMOTE:-172.16.0.1}
gre_gateway=${GRE_GATEWAY:-0.0.0.0}
pim_gw=${PIM_GW:-${gre_remote}}

ipsec_key=${IPSEC_KEY:-1234}
ipsec_local=${IPSEC_LOCAL:-75.0.0.1}

# Create a GRE tunnel
ip link add g0 type gre key $gre_key remote $gre_gateway ttl 64
ip link set g0 multicast on
ip addr add $gre_local dev g0
ip link set g0 up

ip route add $pim_rp/32 via $pim_gw

cat <<EOF > /etc/pimd.conf
phyint g0 enable igmpv3
phyint $pim_eth0 enable igmpv3
rp-address $pim_rp 224.0.0.0/4
EOF

cat <<EOF > /etc/opennhrp/opennhrp.conf
interface g0
  map $gre_remote/24 $gre_gateway register cisco
  cisco-authentication 1234
  holding-time 300
  multicast nhs
EOF

cat <<EOF > /etc/swanctl/conf.d/dmvpn.conf
connections {
    DMVPN {
        version = 2
        rekey_time = 25920s
        over_time = 2880s
        local_addrs = $ipsec_local
        remote_addrs = %any
        proposals = aes256-sha384-ecp384
        local {
            auth = psk
        }
        local_port = 500
        remote {
            auth = psk
        }
        dpd_delay = 30
        dpd_timeout = 105
        children {
            DMVPN {
                mode = transport
                remote_ts = dynamic[47/]
                local_ts = dynamic[47/]
                start_action = trap
                close_action = trap
                dpd_action = trap
                esp_proposals = aes256gcm16-ecp384
                rekey_time = 3240s
                life_time = 3600s
                sha256_96 = no
            }
        }
        mobike = no
        unique = replace
    }
}

secrets {
  ike {
    id = $ipsec_local
    secret = $ipsec_key
  }
}
EOF

iptables-legacy -t nat -I POSTROUTING -o g0 -p tcp --dport 179 -j MASQUERADE

ipsec start
# wait for /var/run/charon.vivi
while [ ! -e /var/run/charon.vici ]; do
    sleep 1
done
swanctl --load-all

opennhrp -c /etc/opennhrp/opennhrp.conf & 

exec "$@"