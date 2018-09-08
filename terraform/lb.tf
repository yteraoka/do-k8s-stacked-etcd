resource "digitalocean_loadbalancer" "k8s_api" {
  name = "cp-lb"
  region = "${var.region}"
  forwarding_rule {
    entry_port = 443
    entry_protocol = "tcp"

    target_port = 6443
    target_protocol = "tcp"
  }
  healthcheck {
    port = 6443
    protocol = "tcp"
  }
  droplet_tag = "control-plane"
}
