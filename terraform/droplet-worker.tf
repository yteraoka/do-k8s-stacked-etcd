resource "digitalocean_droplet" "worker" {
  count = "${var.number_of_worker}"
  name = "worker-${count.index}"
  image = "${var.image_name}"
  region = "${var.region}"
  size = "${var.worker_droplet_size}"
  ssh_keys = "${var.ssh_key_ids}"
  monitoring = true
  private_networking = true
  tags = [
    "${digitalocean_tag.k8s.id}",
    "${digitalocean_tag.worker.id}"
  ]
}
