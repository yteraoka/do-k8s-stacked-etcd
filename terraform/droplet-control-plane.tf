resource "digitalocean_droplet" "cp1" {
  name = "cp1"
  image = "${var.image_name}"
  region = "${var.region}"
  size = "${var.cp_droplet_size}"
  ssh_keys = "${var.ssh_key_ids}"
  monitoring = true
  private_networking = true
  tags = [
    "${digitalocean_tag.k8s.id}",
    "${digitalocean_tag.control-plane.id}",
    "${digitalocean_tag.first.id}"
  ]
}

resource "digitalocean_droplet" "cp2" {
  name = "cp2"
  image = "${var.image_name}"
  region = "${var.region}"
  size = "${var.cp_droplet_size}"
  ssh_keys = "${var.ssh_key_ids}"
  monitoring = true
  private_networking = true
  tags = [
    "${digitalocean_tag.k8s.id}",
    "${digitalocean_tag.control-plane.id}",
    "${digitalocean_tag.second.id}"
  ]
}

resource "digitalocean_droplet" "cp3" {
  name = "cp3"
  image = "${var.image_name}"
  region = "${var.region}"
  size = "${var.cp_droplet_size}"
  ssh_keys = "${var.ssh_key_ids}"
  monitoring = true
  private_networking = true
  tags = [
    "${digitalocean_tag.k8s.id}",
    "${digitalocean_tag.control-plane.id}",
    "${digitalocean_tag.third.id}"
  ]
}
