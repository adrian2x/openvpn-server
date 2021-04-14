# get updates
echo "Updating the system..."
sudo apt-get -y update
sudo apt-get -y upgrade

# install dependencies
sudo apt-get -y install squid apache2-utils
sudo touch /etc/squid/.squid_passwd
sudo chown ubuntu /etc/squid/.squid_passwd

# setup squid config
wget --no-cache https://raw.githubusercontent.com/adrian2x/openvpn-server/main/squid.conf
cp -f ./squid.conf /etc/squid/squid.conf

echo "Setting up client profile..."
key=$(openssl rand -base64 32)
read -p "Enter a new username for client: " client_name
sudo htpasswd -bB /etc/squid/.squid_passwd "$client_name" "$key"

# set listening rules
sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 3128 -j ACCEPT
# sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 80 -j ACCEPT
sudo netfilter-persistent save
sudo firewall-cmd --zone=trusted --permanent --add-port=3128/tcp
sudo firewall-cmd --zone=public --permanent --add-port=3128/tcp
sudo firewall-cmd --reload
sudo systemctl restart squid

echo "Done! Use ${client_name} and ${key}"

# sudo vim /etc/iptables/rules.v4
# -A IN_public_allow -p udp -m tcp --dport 3128 -m conntrack --ctstate NEW,UNTRACKED -j ACCEPT
sudo echo "-A IN_public_allow -p udp -m tcp --dport 3128 -m conntrack --ctstate NEW,UNTRACKED -j ACCEPT
" >> /etc/iptables/rules.v4
