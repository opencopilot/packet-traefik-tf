#!/bin/sh
set -x

#### Fetch Metadata ###
META_DATA=$(mktemp /tmp/bootstrap_metadata.json.XXX)
curl -sS metadata.packet.net/metadata > $META_DATA

PRIV_IP=$( cat $META_DATA | jq -r '.network.addresses[] | select(.management == true) | select(.public == false) | select(.address_family == 4) | .address')
PUB_IP=$( cat $META_DATA | jq -r '.network.addresses[] | select(.management == true) | select(.public == true) | select(.address_family == 4) | .address')
PACKET_AUTH=${packet_token}
PACKET_PROJ=${project_id}
BACKEND_TAG=${backend_tag}

mkdir /etc/traefik

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
[acme]
  email = "${lets_encrypt_email}"
  storage = "/etc/traefik/acme.json"
  entryPoint = "https"
  acmeLogging = true
[acme.httpChallenge]
  entryPoint = "http"
[[acme.domains]]
  main = "${main_domain}"
  sans = []
[api]
  entryPoint = "traefik"
  dashboard = true
[rest]
[metrics]
  # To enable Traefik to export internal metrics to Prometheus
  [metrics.prometheus]
[accessLog]
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
ExecStart=/usr/bin/docker run --name traefik -p $PRIV_IP:8080:8080 -p 80:80 -p 443:443 -v /etc/traefik/traefik.toml:/etc/traefik/traefik.toml traefik
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
ExecStart=/usr/bin/docker run --name traefik-packet -e PACKET_AUTH=$PACKET_AUTH -e PACKET_PROJ=$PACKET_PROJ -e BACKEND_TAG=$BACKEND_TAG quay.io/opencopilot/traefik-packet
ExecStop=/usr/bin/docker stop traefik-packet

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl enable /etc/systemd/system/traefik-packet.service
sudo systemctl start traefik-packet.service