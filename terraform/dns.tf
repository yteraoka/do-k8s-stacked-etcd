resource "digitalocean_record" "lb" {
  domain = "${var.domain_suffix}"
  type = "A"
  name = "k8s-api"
  value = "${digitalocean_loadbalancer.k8s_api.ip}"
  ttl = 60
}
