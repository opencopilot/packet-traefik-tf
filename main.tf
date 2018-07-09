data "template_file" "init" {
  template = "${file("${path.module}/templates/userdata.sh.${var.os_version}.tpl")}"

  vars = {
    count        = "${var.count}"
    project_id   = "${var.project_id}"
    packet_token = "${var.packet_token}"
    facility     = "${var.facility}"
    backend_tag  = "${var.backend_tag}"

    lets_encrypt_email = "${var.lets_encrypt_email}"
  }
}

resource "packet_device" "traefik-lb" {
  count            = "${var.count}"
  hostname         = "${var.hostname != "" ? "${var.hostname}" : "prod-${format("traefik-%03d", count.index + 1)}" }"
  plan             = "${var.plan}"
  facility         = "${var.facility}"
  operating_system = "${var.os_version}"
  billing_cycle    = "hourly"
  project_id       = "${var.project_id}"
  tags             = ["traefik-lb"]

  user_data = "${data.template_file.init.rendered}"
}
