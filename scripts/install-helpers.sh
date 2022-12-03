#!/usr/bin/env bash

#download and extract the node-exporter binary

install_node_exporter () {
    curl -L --output /tmp/node_exporter-1.5.0.linux-amd64.tar.gz https://github.com/prometheus/node_exporter/releases/download/v1.5.0/node_exporter-1.5.0.linux-amd64.tar.gz
    tar xvfz /tmp/node_exporter-1.5.0.linux-amd64.tar.gz -C /opt

    chmod 644 /etc/systemd/system/prometheus-node-exporter.service
    systemctl start prometheus-node-exporter.service
    systemctl enable prometheus-node-exporter.service
}

configure_nginx () {
    # uses an arg to make this more dynamic 
    mv /tmp/$1-nginx.conf /etc/nginx/sites-available/$1-nginx.conf
    ln -s /etc/nginx/sites-available/$1-nginx.conf /etc/nginx/sites-enabled/$1-nginx.conf
    unlink /etc/nginx/sites-enabled/default
    nginx -s reload
}

configure_ssl () {
    apt install snapd -y
    snap install core
    snap install --classic certbot
    ln -s /snap/bin/certbot /usr/bin/certbot

    local -a nameservers=(
    '8.8.4.4'
    '8.8.8.8'
    )

    for i in ${nameservers[@]}; do
        local a=1
        printf "Waiting for propagation to %s" $i
        while [ $a -gt 0 ]; do
            result="$(dig @$i +short $1)"
            if [ "$result" == $(hostname -i) ]; then
                ((a-=1))
                result=''
            else
                printf "."
                sleep 10
            fi
        done
        printf "done.\n"
    done

    printf "\n%s has finished propagating!\n" $1

    certbot --nginx --agree-tos -d $1 -m $2 -n --test-cert
}
