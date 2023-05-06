#!/bin/bash
cd /tmp

wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg \
--dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg

sudo chmod 644 /usr/share/keyrings/elasticsearch-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] \
https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee \
/etc/apt/sources.list.d/elastic-8.x.list

sudo apt update && sudo apt install elasticsearch -y

echo "ES_JAVA_OPTS=\"-Djava.io.tmpdir=/var/lib/elasticsearch/tmp\"" | sudo tee -a /etc/default/elasticsearch

sudo mkdir -p /var/lib/elasticsearch/tmp
sudo chown -R elasticsearch:root /var/lib/elasticsearch
sudo chmod 775 -R /var/lib/elasticsearch

sudo systemctl start elasticsearch
sudo systemctl enable elasticsearch