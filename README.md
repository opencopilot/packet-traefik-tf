### packet-traefik-tf

This is a terraform module for deploying a standalone [`traefik`](https://traefik.io/) load balancer on Packet bare metal. A sidecar container is run which looks for backends via tags on Packet devices and auto-configures `traefik` to route to those devices on port `80` of the private management IP. More flexible configuration will be exposed soon.

The `traefik` dashboard and management endpoint is bound to the private IP of the Packet device (on port `8080`, use the [Packet VPN](https://help.packet.net/technical/infrastructure/doorman-customer-vpn) or an SSH tunnel to access the dashboard.

Any elastic IPs you add to the instance this provisions will be automatically added to the loopback of the host, which `traefik` will listen on. So if you add an elastic Global IP in the Packet portal to this device, the load balancer will be available on that IP automatically.

In order to add hostnames for `Let's Encrypt` certs to "just work," add device tags to the load balancer device that gets provisioned in the format `hostname=www.mydomain.com`. Make sure that your domain has an A record with an IP attached to your LB device (either the public management IP or an attached elastic IP). If the ACME challenge process fails due to a DNS resolution error (you added the A record after adding the device tag), just remove the hostname tag and re-add it. By default, your LB will be accessible at `<device-short-id>.packethost.net` where `<device-short-id>` is the first section (split on `-`) of your Packet device's ID, with a valid cert.

#### What you get
- Automatic backend configuration via tags on Packet devices (add/remove backends by adding/removing tags on your Packet device)
- Automatic `Let's Encrypt` for zero-config SSL termination at the load balancer. Use device tags to configure what hostnames to generate certificates for
- `Traefik` dashboard/api exposed on private IP for internal visibility
- Load balancer metrics exposed on private IP for prometheus scraping
- Access logs (TODO: will be configurable to be sent to a remote service)
- Automatic Packet elastic IP set-up, add IPs to the device in the Packet portal and the LB will "just work" on that IP

#### Who is this useful for?

This may be useful for anyone looking for a simple round robin load balancer on Packet that can "auto discover" backends based on Packet device tags, with HTTPS, metrics, logs and remote dashboard visibility out of the box. Much of the magic comes from `traefik` itself and it's ease of use with minimal configuration; the sidecar containers are what enables easier integration with Packet.

For more opinionated needs in a `traefik` load balancer, the `traefik.toml` file lives in `/etc/traefik/traefik.toml` and can be configured however you like.

The goal is to offer a load balancer that "just works" out of the box, but can easily be modified to work with your own automation/config-management for more opinionated use cases.


#### TODO
- Configuration for sending load balancer access logs somewhere
- Easier HA setup with Packet BGP for ECMP

#### Usage

```tf
provider "packet" {
  auth_token = "${var.packet_token}"
}

module "packet-lb" {
  source             = "github.com/opencopilot/packet-traefik-tf"
  count              = 1
  packet_token       = "${var.packet_token}"
  project_id         = "${var.packet_project_id}"
  facility           = "ewr1"
  plan               = "c1.large"
  lets_encrypt_email = "email@domain.com"
  main_domain        = "example.com"
}
```
