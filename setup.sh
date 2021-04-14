# get updates
apt-get update && apt-get upgrade
read -p "Enter a new username for vpn: " username
useradd -G sudo -m ${username} -s /bin/bash
passwd ${username}

sudo apt get install wget
# wget https://git.io/vpn -O openvpn-install.sh
# sudo chmod +x openvpn-install.sh
sudo bash openvpn-install.sh
1

sudo mv /root/${username}.ovpn ~/
sudo systemctl restart openvpn-server@server.service

ip=`ip addr show |grep "inet " |grep -v 127.0.0. |head -1|cut -d" " -f6|cut -d/ -f1`
echo "Download your client profile like this:"
echo "scp root@${ip}:~/${username}.ovpn ."
