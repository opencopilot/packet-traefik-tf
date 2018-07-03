variable "project_id" {
  description = "The Packet project id this load balancer will be deployed in"
}
variable "packet_token" {
  description = "A Packet API token. Ideally this dependence will be removed when Packet metadata can provide more info"
}

variable "count" {
  default = 1
  description = "How many load balancer instances to provision. Coming soon: HA with Packet BGP"
}

variable "backend_tag" {
  default = "traefik-backend"
  description = "The tag the sidecar container will look for devices on to route to as backends"
}

variable "facility" {
  description = "The Packet datacenter to provision in"
}
variable "plan" {
  description = "The Packet plan/server type to provision for this load balancer"
}

variable "os_version" {
  default = "coreos_stable"
  description = "OS version, current opions are `coreos_stable` and `ubuntu_16_04`"
}

variable "hostname" {
  default = ""
  description = "The hostname of the device"
}

variable "lets_encrypt_email" {
  description = "The email to use for Let's Encrypt"
}
variable "main_domain" {
  description = "Main domain for traefik <> Let's Encrypt integration"
}