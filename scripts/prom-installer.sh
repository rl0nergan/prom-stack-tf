#!/usr/bin/env bash

## Enable logging for the StackScript
exec 1> >(tee -a "/var/log/prom-install.log") 2>&1
set -xo pipefail

source /tmp/install-helpers.sh

install_prometheus () {
    curl -L --output /tmp/prometheus-2.37.4.linux-amd64.tar.gz https://github.com/prometheus/prometheus/releases/download/v2.37.4/prometheus-2.37.4.linux-amd64.tar.gz
    tar xvfz /tmp/prometheus-2.37.4.linux-amd64.tar.gz -C /opt

    chmod 644 /etc/systemd/system/prometheus.service
    systemctl start prometheus.service
    systemctl enable prometheus.service
}

install_node_exporter
install_prometheus

sleep 60

configure_nginx "prometheus"

ufw allow http
ufw allow https

#configure_ssl "prom-test2.jnkyrd.dog" "ryan.tlonergan@gmail.com"