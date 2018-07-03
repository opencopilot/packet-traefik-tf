#!/bin/sh
set -x

#### Install Docker ###
curl -fsSL get.docker.com -o get-docker.sh
sh get-docker.sh

#### Fetch Metadata ###
META_DATA=$(mktemp /tmp/bootstrap_metadata.json.XXX)
curl -sS metadata.packet.net/metadata > $META_DATA

PRIV_IP=$( jq -r '.network.addresses[] | select(.management == true) | select(.public == false) | select(.address_family == 4) | .address' $METADATA)
PUB_IP=$( jq -r '.network.addresses[] | select(.management == true) | select(.public == true) | select(.address_family == 4) | .address' $META_DATA)
PACKET_AUTH=${packet_token}
PACKET_PROJ=${project_id}
BACKEND_TAG=${backend_tag}

mkdir /etc/traefik

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

docker run -d \
    -p $PRIV_IP:8080:8080 \
    -p 80:80 \
    -p 443:443 \
    -v /etc/traefik/traefik.toml:/etc/traefik/traefik.toml \
    --restart=always \
    traefik


docker run -d \
    -e PACKET_AUTH=$PACKET_AUTH \
    -e PACKET_PROJ=$PACKET_PROJ \
    -e BACKEND_TAG=$BACKEND_TAG \
    --restart=always \
    quay.io/opencopilot/traefik-packet

docker run -d \
  --name packet-ip-sidecar \
  --net host \
  --privileged \
  --restart=always \
  quay.io/opencopilot/packet-ip-sidecar