resource "digitalocean_tag" "k8s" {
  name = "k8s"
}

resource "digitalocean_tag" "control-plane" {
  name = "control-plane"
}

resource "digitalocean_tag" "worker" {
  name = "worker"
}

resource "digitalocean_tag" "first" {
  name = "first"
}

resource "digitalocean_tag" "second" {
  name = "second"
}

resource "digitalocean_tag" "third" {
  name = "third"
}
