variable "domain_suffix" {}

variable "image_name" {
  # default = "ubuntu-16-04-x64"
  default = "centos-7-x64"
}

variable "cp_droplet_size" {
  default = "s-1vcpu-3gb"
}

variable "number_of_worker" {
  default = 1
}

variable "worker_droplet_size" {
  default = "s-1vcpu-2gb"
}

variable "region" {
  default = "sgp1"
}

variable "ssh_key_ids" {
  type = "list"
  default = ["16797382","18482899"]
}
