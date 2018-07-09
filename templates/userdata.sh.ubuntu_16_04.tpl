#!/bin/sh
set -x

#### Fetch Metadata ###
META_DATA=$(mktemp /tmp/bootstrap_metadata.json.XXX)
curl -sS metadata.packet.net/metadata > $META_DATA

PRIV_IP=$(cat $META_DATA | jq -r '.network.addresses[] | select(.management == true) | select(.public == false) | select(.address_family == 4) | .address')
PUB_IP=$(cat $META_DATA | jq -r '.network.addresses[] | select(.management == true) | select(.public == true) | select(.address_family == 4) | .address')
DEV_ID=$(cat $META_DATA | jq -r .id)
SHORT_ID=($${DEV_ID//-/ })
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

docker run -d \
    -p $PRIV_IP:8080:8080 \
    -p 80:80 \
    -p 443:443 \
    -v /etc/traefik:/etc/traefik \
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
  --cap-add NET_ADMIN \
  --restart=always \
  quay.io/opencopilot/packet-ip-sidecar