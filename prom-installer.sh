#!/usr/bin/env bash

#download and extract the prometheus binary

curl -L --output /tmp/prometheus-2.37.4.linux-amd64.tar.gz https://github.com/prometheus/prometheus/releases/download/v2.37.4/prometheus-2.37.4.linux-amd64.tar.gz
tar xvfz prometheus-2.37.4.linux-amd64.tar.gz -C /opt

mkdir /etc/prometheus


cat > /lib/systemd/system/prometheus.service <<EOF
[Unit]
Description=Prometheus service.

[Service]
Type=simple
ExecStart=/opt/prometheus-2.37.4.linux-amd64 --config.file=/etc/prometheus/prometheus.yml

[Install]
WantedBy=multi-user.target
EOF