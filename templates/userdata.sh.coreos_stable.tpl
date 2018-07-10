#!/bin/sh
set -x

#### Fetch Metadata ####
META_DATA=$(mktemp /tmp/bootstrap_metadata.json.XXX)
curl -sS metadata.packet.net/metadata > $META_DATA

PRIV_IP=$(cat $META_DATA | jq -r '.network.addresses[] | select(.management == true) | select(.public == false) | select(.address_family == 4) | .address')
PUB_IP=$(cat $META_DATA | jq -r '.network.addresses[] | select(.management == true) | select(.public == true) | select(.address_family == 4) | .address')
DEV_ID=$(cat $META_DATA | jq -r .id)
SHORT_ID=$(echo $DEV_ID | cut -d'-' -f1)
PACKET_AUTH=${packet_token}
PACKET_PROJ=${project_id}
BACKEND_TAG=${backend_tag}

mkdir /etc/traefik
mkdir /etc/docker

echo '{"log-driver": "${log_driver}"} {"log-opts": ${log_driver_opts}}' | jq -s add >> /etc/docker/daemon.json

# Create Traefik config
cat > /etc/traefik/traefik.toml <<EOF
[entryPoints]
  [entryPoints.http]
  address = ":80"
  [entryPoints.http.redirect]
     entryPoint = "https"
  [entryPoints.https]
  address = ":443"
    [entryPoints.https.tls]
[api]
  entryPoint = "traefik"
  dashboard = true
[rest]
[retry]
[acme]
  email = "${lets_encrypt_email}"
  storage = "/etc/traefik/acme.json"
  entryPoint = "https"
  onHostRule = true
  [acme.httpChallenge]
    entryPoint = "http"
[metrics]
  # To enable Traefik to export internal metrics to Prometheus
  [metrics.prometheus]
[accessLog]
[file]
  directory = "/etc/traefik/"
  watch = true
EOF

# Start Traefik
cat > /etc/systemd/system/traefik.service <<EOF
[Unit]
Description=Traefik
After=docker.service
Requires=docker.service

[Service]
TimeoutStartSec=0
ExecStartPre=/usr/bin/docker pull traefik
ExecStart=/usr/bin/docker run --rm --name traefik -p $PRIV_IP:8080:8080 -p 80:80 -p 443:443 -v /etc/traefik:/etc/traefik traefik
ExecStop=/usr/bin/docker stop traefik

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl enable /etc/systemd/system/traefik.service
sudo systemctl start traefik.service


# Start Traefik Packet
cat > /etc/systemd/system/traefik-packet.service <<EOF
[Unit]
Description=Traefik Packet
After=docker.service
Requires=docker.service

[Service]
TimeoutStartSec=0
ExecStartPre=/usr/bin/docker pull quay.io/opencopilot/traefik-packet
ExecStart=/usr/bin/docker run --rm --name traefik-packet -e PACKET_AUTH=$PACKET_AUTH -e PACKET_PROJ=$PACKET_PROJ -e BACKEND_TAG=$BACKEND_TAG quay.io/opencopilot/traefik-packet
ExecStop=/usr/bin/docker stop traefik-packet

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl enable /etc/systemd/system/traefik-packet.service
sudo systemctl start traefik-packet.service


# Start Packet IP Sidecar
cat > /etc/systemd/system/packet-ip-sidecar.service <<EOF
[Unit]
Description=Packet IP Sidecar
After=docker.service
Requires=docker.service

[Service]
TimeoutStartSec=0
ExecStartPre=/usr/bin/docker pull quay.io/opencopilot/packet-ip-sidecar
ExecStart=/usr/bin/docker run --rm --name packet-ip-sidecar --net host --cap-add NET_ADMIN quay.io/opencopilot/packet-ip-sidecar
ExecStop=/usr/bin/docker stop packet-ip-sidecar

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl enable /etc/systemd/system/packet-ip-sidecar.service
sudo systemctl start packet-ip-sidecar.service