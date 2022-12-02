terraform {
  required_providers {
    linode = {
      source = "linode/linode"
      version = "1.29.4"
    }
  }
}

provider "linode" {
  token = "op://Private/Linode API Access Token/password"
}

data "linode_profile" "me" {}

resource "linode_instance" "prometheus" {
        image = "linode/debian11"
        label = "prometheus"
        group = "prom-stack"
        region = "us-southeast"
        type = "g6-dedicated-2"
        authorized_users = [ data.linode_profile.me.username ]
        root_pass = "op://Private/prom-stack/password"
        stackscript_id = 1095232
        stackscript_data = {
          "disable_root": "No"
        }
}

provisioner "file" {
  source      = "script.sh"
  destination = "/tmp/script.sh"
}  

provisioner "remote-exec" {
  inline = [
    "puppet apply",
    "consul join ${aws_instance.web.private_ip}",
  ]
}

resource "linode_instance" "grafana" {
        image = "linode/debian11"
        label = "grafana"
        group = "prom-stack"
        region = "us-southeast"
        type = "g6-standard-1"
        authorized_users = [ data.linode_profile.me.username ]
        root_pass = "op://Private/prom-stack/password"
        stackscript_id = 1095232
        stackscript_data = {
          "disable_root": "No"
        }
}

resource "linode_instance" "thanos" {
        image = "linode/debian11"
        label = "thanos"
        group = "prom-stack"
        region = "us-southeast"
        type = "g6-nanode-1"
        authorized_users = [ data.linode_profile.me.username ]
        root_pass = "op://Private/prom-stack/password"
        stackscript_id = 1095232
        stackscript_data = {
          "disable_root": "No"
        }
}

resource "linode_volume" "prom-data" {
    label = "prom-data"
    region = linode_instance.prometheus.region
    linode_id = linode_instance.prometheus.id
    size = 50
}

data "linode_object_storage_cluster" "primary" {
    id = "us-southeast-1"
}

resource "linode_object_storage_key" "prom-stack-key" {
    label = "prom-stack-key"
}

resource "linode_object_storage_bucket" "prom-data" {
  cluster = data.linode_object_storage_cluster.primary.id
  label = "prom-data"
  access_key = linode_object_storage_key.prom-stack-key.access_key
  secret_key = linode_object_storage_key.prom-stack-key.secret_key
}