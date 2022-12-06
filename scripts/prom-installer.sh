#!/usr/bin/env bash

## Enable logging for the StackScript
exec 1> >(tee -a "/var/log/prom-install.log") 2>&1
set -xo pipefail

source /tmp/install-helpers.sh

mkfs.ext4 /dev/disk/by-id/scsi-0Linode_Volume_${1}
mkdir /var/lib/prometheus
mount /dev/disk/by-id/scsi-0Linode_Volume_${1} /var/lib/prometheus
echo "/dev/disk/by-id/scsi-0Linode_Volume_vol355452-pvc3131c5e391a54840-b7 /mnt/vol355452-pvc3131c5e391a54840-b7 ext4 defaults,noatime,nofail 0 2" >> /etc/fstab

install_prometheus () {
    curl -L --output /tmp/prometheus-2.40.5.linux-amd64.tar.gz https://github.com/prometheus/prometheus/releases/download/v2.40.5/prometheus-2.40.5.linux-amd64.tar.gz
    tar xvfz /tmp/prometheus-2.40.5.linux-amd64.tar.gz -C /opt

    chmod 644 /etc/systemd/system/prometheus.service
    systemctl start prometheus.service
    systemctl enable prometheus.service
}

install_node_exporter
install_prometheus

sleep 60

ufw allow http
ufw allow https

configure_nginx "prometheus"

configure_ssl 'prom.jnkyrd.dog' 'ryan.tlonergan@gmail.com'

#configure_ssl "prom-test2.jnkyrd.dog" "ryan.tlonergan@gmail.com"


