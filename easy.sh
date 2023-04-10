#!/bin/bash

parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd "$parent_path" || { echo "Error cd into parent_path"; exit 1; }

DOMAIN_NAME=""
DATA_PORT=""
CONTROL_PORT=""
FAKE_SITE=""

POSITIONAL_ARGS=()

[ $# -lt 4 ] || [ $# -gt 4 ] && {
    echo "Usage: easy -d domain_name -p data_port -c control_port -f fake_site_domain_name" >&2
    return 1
}

while [[ $# -gt 0 ]]; do
  case $1 in
    -d|--domain-name)
      DOMAIN_NAME="$2"
      shift # past argument
      shift # past value
      ;;
    -p|--data-port)
      DATA_PORT="$2"
      shift # past argument
      shift # past value
      ;;
    -c|--control-port)
      CONTROL_PORT="$2"
      shift # past argument
      shift # past value
      ;;
    -f|--fake-site)
      FAKE_SITE="$2"
      shift # past argument
      shift # past value
      ;;
    --default)
      DEFAULT=YES
      shift # past argument
      ;;
    -*|--*)
      echo "Unknown option $1"
      exit 1
      ;;
    *)
      POSITIONAL_ARGS+=("$1") # save positional arg
      shift # past argument
      ;;
  esac
done

set -- "${POSITIONAL_ARGS[@]}" # restore positional parameters

echo DOMAIN_NAME: $DOMAIN_NAME
echo DATA_PORT: $DATA_PORT
echo CONTROL_PORT: $CONTROL_PORT
echo FAKE_SITE: $FAKE_SITE

#not null
if [[ -n $1 ]]; then
    echo "Non-opt/last argument:"
    echo "$1"
fi

# read -p "Skip login script [Yy]" -n 1 -r
# echo    # (optional) move to a new line
# if [[ $REPLY =~ ^[Yy]$ ]] ; then
# # do dangerous stuff
    # exit 0
# else
    # echo running login sh
# fi

#========================
i=120 ;
echo 
echo Warning If Yes :
echo Warning will start install xui, control sysctl, install nginx, and edit the nginx.conf
echo
while ((i-->1)) && ! read -sn 1 -t 1 -p $'\rContinue install (Y/y/Enter = Yes)? '$i$'..\e[3D' answer;
    do
        :;
    done ;
#key in n or N , then answer = No,  anything else including enter = Yes
#[[ $answer == [nN] ]] && answer=No || answer=Yes ;

#check if its enter key:
#echo answer: $answer
#always 0
#echo exit code is $?
if [[ -z $answer || ${#answer} -eq 0 ]] ; then 
    #echo "answer is empty (Enter was hit?)"
    answer="Y"
fi

#y or Y, its yes, anything else including Enter, is no
#[[ $answer == [yY] ]] && answer=Yes || answer=No ;

echo "$answer "
if [[ $answer == [yY] ]] ; then
    clear
    echo installing...
else
    echo Cancelled.
    exit 0
fi

#更新软件源
sudo apt update && sudo apt upgrade -y
#启用 BBR TCP 拥塞控制算法
echo "net.core.default_qdisc=fq" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" | sudo tee -a /etc/sysctl.conf
#QUIC receiving buffer
echo "net.core.rmem_max = 2500000" | sudo tee -a /etc/sysctl.conf
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
sudo certbot certonly --standalone --preferred-challenges http -d $DOMAIN_NAME

sudo chown -R www-data: /etc/letsencrypt
sudo chmod -R 777 /etc/letsencrypt

sudo cp -v /etc/nginx/nginx.conf ./nginx.conf.backup.original
sudo cp -vf ./nginx.conf /etc/nginx/
sudo chmod 660 /etc/nginx/nginx.conf
sudo sed -i "s/nicename.co/$DOMAIN_NAME/g" /etc/nginx/nginx.conf
sudo sed -i "s/data_port/$DATA_PORT/g" /etc/nginx/nginx.conf
sudo sed -i "s/control_port/$CONTROL_PORT/g" /etc/nginx/nginx.conf
sudo sed -i "s/bing.com/$FAKE_SITE/g" /etc/nginx/nginx.conf
sudo chown -R www-data: /etc/nginx
sudo nginx -t
sudo systemctl restart nginx



