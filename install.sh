#!/bin/bash
domain_name=$1
data_port=$2
control_port=$3
fake_site=$4

#更新软件源
sudo apt update && sudo apt upgrade -y
#启用 BBR TCP 拥塞控制算法
echo "net.core.default_qdisc=fq" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

#安装x-ui：
bash <(curl -Ls https://raw.githubusercontent.com/vaxilu/x-ui/master/install.sh)

# if want to uninstall nginx totally first
# sudo apt-get purge nginx nginx-common nginx-full  -y

#安装nginx
sudo apt install nginx -y

#stop so we can run the certbot on 80 port 
sudo systemctl stop nginx
sudo apt install certbot -y
sudo certbot certonly --standalone --preferred-challenges http -d $domain_name

sudo chown -R www-data: /etc/letsencrypt
sudo chmod -R 777 /etc/letsencrypt

sudo cp -v /etc/nginx/nginx.conf ./nginx.conf.backup.original
sudo cp -vf ./nginx.conf /etc/nginx/
sudo chmod 660 /etc/nginx/nginx.conf
sudo sed -i "s/nicename.co/$domain_name/g" /etc/nginx/nginx.conf
sudo sed -i "s/data_port/$data_port/g" /etc/nginx/nginx.conf
sudo sed -i "s/control_port/$control_port/g" /etc/nginx/nginx.conf
sudo sed -i "s/bing.com/$fake_site/g" /etc/nginx/nginx.conf
sudo chown -R www-data: /etc/nginx
sudo nginx -t
sudo systemctl restart nginx



