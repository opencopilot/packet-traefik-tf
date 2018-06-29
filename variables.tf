variable "project_id" {}
variable "packet_token" {}

variable "count" {
  default = 1
}

variable "backend_tag" {
  default = "traefik-backend"
}

variable "facility" {}
variable "plan" {}

variable "lets_encrypt_email" {}
variable "main_domain" {}