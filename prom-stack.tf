terraform {
  required_providers {
    linode = {
      source  = "linode/linode"
      version = "1.29.4"
    }
  }
}

variable "root_password" {}

variable "linode_api_token" {}

variable "ssh_pubkey" {
  type    = string
  default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC/X4hgv7AeYtNns7CE0ZCKBjTCRVkxB5ziOc4d82YBuQl3fcPttGnxPCf8SKVEAMtKw+331mXcIL2Yxq+rHaMRDv5r8rwJ/hk3Awyu/Uswe+vpAPFuO3auz2i1tC1NIOqinCCSFLAulsSfCSYn6G+gpEQ1OgdRpD1qQX+QhGjn6P23C731Rw1W1IzO9BSzaqzyLARs8tsC3Q0BPNbsuAgC4f4UmWenJzgU+gaT/8PExLHV1Exs4D8KW+Vvag3DN26oaXDvf4y0eQWuGEOoTs1P6k1nNPO/NE7X0YbB5cFR1TzWJzn4J/PrW90VDv2OmV8K8ZFvQ6FNBsdz0BoXGWILSxp37CiwaTbsdOWIJ9u20jKj19LzpTRB3qKG7fDph03+Re9dXbxNGwJm5INzMZ/89pR+esmZ0/sMgw+0MkeXqSFdsRPatemjhDjMUMVgQOumP+ICfRFU1kDtUZBTzzLnnU6zKlT0PRDuXiLd9vhI7JAknL0xYygh8gbWE9Fjds1ytfNO9I4bpr3O66icMk6631Kx8PyWAlVHJUurHYlL8LC06AFfGhznuph5TVmu/F60ojUQYDyxqNSvjYJVAaF1atlR5qXpWafLW09k4wAippotiVhjWSjpmUUOR2vOC3+M+VYbstW9fBLAe++AJKEK23QYwXwMTptR4YsyFmf02w== rlonergan@rlonergan-C02ZW8AVMD6M"
}

provider "linode" {
  token = var.linode_api_token
}

data "linode_profile" "me" {}

resource "linode_instance" "prometheus" {
  image            = "linode/debian11"
  label            = "prometheus"
  group            = "prom-stack"
  region           = "us-southeast"
  type             = "g6-dedicated-2"
  tags             = ["prom-stack"]
  private_ip       = true
  authorized_users = [data.linode_profile.me.username]
  root_pass        = var.root_password
  stackscript_id   = 1095232
  stackscript_data = {
    "username" : "prometheus",
    "password" : "${var.root_password}",
    "pubkey" : "${var.ssh_pubkey}",
    "disable_root" : "No"
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir /etc/prometheus"
    ]
  }

  provisioner "file" {
    source      = "./configs/prometheus.yml"
    destination = "/etc/prometheus/prometheus.yml"
  }

  provisioner "file" {
    source      = "./configs/prometheus.service"
    destination = "/etc/systemd/system/prometheus.service"
  }

  provisioner "file" {
    source      = "./configs/prometheus-node-exporter.service"
    destination = "/etc/systemd/system/prometheus-node-exporter.service"
  }

  provisioner "file" {
    source      = "./configs/prometheus-nginx.conf"
    destination = "/tmp/prometheus-nginx.conf"
  }

  # provisioner "file" {
  #   source      = "./scripts/configure-ssl.sh"
  #   destination = "/tmp/configure-ssl.sh"
  # }

  connection {
    type     = "ssh"
    user     = "root"
    password = var.root_password
    host     = self.ip_address
  }

}

resource "linode_volume" "prom-data" {
    label = "prom-data"
    region = linode_instance.prometheus.region
    linode_id = linode_instance.prometheus.id
    size = 50
}

resource "linode_domain_record" "prometheus-A" {
  domain_id   = 1395459
  name        = "prom"
  record_type = "A"
  target      = linode_instance.prometheus.ip_address
  ttl_sec     = 30
}

# resource "linode_domain_record" "prometheus-AAAA" {
#     domain_id = 1395459
#     name = "prom"
#     record_type = "AAAA"
#     target = linode_instance.prometheus.ipv6
#     ttl_sec = 30
# }

resource "null_resource" "configure_prometheus" {
  connection {
    type     = "ssh"
    user     = "root"
    password = var.root_password
    host     = linode_instance.prometheus.ip_address
  }
  provisioner "file" {
    source      = "./scripts/install-helpers.sh"
    destination = "/tmp/install-helpers.sh"
  }

  provisioner "file" {
    source      = "./scripts/prom-installer.sh"
    destination = "/tmp/prom-installer.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/prom-installer.sh",
      "/tmp/prom-installer.sh ${linode_volume.prom-data.label}"
    ]
  }

  # provisioner "remote-exec" {
  #   inline = [
  #     "chmod +x /tmp/configure-ssl.sh",
  #     "/tmp/configure-ssl.sh 'prom.jnkyrd.dog' 'ryan.tlonergan@gmail.com'"
  #   ]
  # }
}




# Will use the file and remote-exec 
# provisioner "file" {
#   source      = "prom-installer.sh"
#   destination = "/tmp/prom-installer.sh"
# }  

# provisioner "remote-exec" {
#   inline = [
#     "chmod +x /tmp/prom-installer.sh",
#     "/tmp/prom-installer.sh"
#   ]
# }

# resource "linode_instance" "grafana" {
#         image = "linode/debian11"
#         label = "grafana"
#         group = "prom-stack"
#         region = "us-southeast"
#         type = "g6-standard-1"
#         tags = [ "prom-stack" ]
#         private_ip = true
#         authorized_users = [ data.linode_profile.me.username ]
#         root_pass = "op://Private/prom-stack/password"
#         stackscript_id = 1095232
#         stackscript_data = {
#           "disable_root": "No"
#         }
# }

# resource "linode_instance" "thanos" {
#         image = "linode/debian11"
#         label = "thanos"
#         group = "prom-stack"
#         region = "us-southeast"
#         type = "g6-nanode-1"
#         tags = [ "prom-stack" ]
#         private_ip = true
#         authorized_users = [ data.linode_profile.me.username ]
#         root_pass = "op://Private/prom-stack/password"
#         stackscript_id = 1095232
#         stackscript_data = {
#           "disable_root": "No"
#         }
# }

# data "linode_object_storage_cluster" "primary" {
#     id = "us-southeast-1"
# }

# resource "linode_object_storage_key" "prom-stack-key" {
#     label = "prom-stack-key"
# }

# resource "linode_object_storage_bucket" "prom-data" {
#   cluster = data.linode_object_storage_cluster.primary.id
#   label = "prom-data"
#   access_key = linode_object_storage_key.prom-stack-key.access_key
#   secret_key = linode_object_storage_key.prom-stack-key.secret_key
# }