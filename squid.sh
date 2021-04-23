# get updates
echo "Updating the system..."
sudo apt-get -y update
sudo apt-get -y upgrade

# install dependencies
sudo apt-get -y install squid apache2-utils
sudo touch /etc/squid/.squid_passwd
sudo chown ubuntu /etc/squid/.squid_passwd
sudo chown root /etc/squid/.squid_passwd
sudo apt-get -y install vim firewalld
sudo apt-get install mysql-server libdbd-mysql-perl fail2ban -y

# setup squid config
wget --no-cache https://raw.githubusercontent.com/adrian2x/openvpn-server/main/squid.conf
cp -f ./squid.conf /etc/squid/squid.conf
wget --no-cache https://raw.githubusercontent.com/adrian2x/squid-bandwidth-script/master/bandwidth_calculate
cp -f ./bandwidth_calculate /usr/local/bin/bandwidth_calculate
chmod 755 /usr/local/bin/bandwidth_calculate
wget --no-cache https://raw.githubusercontent.com/adrian2x/squid-bandwidth-script/master/bandwidth_check
cp -f ./bandwidth_check /usr/local/bin/bandwidth_check
chmod 755 /usr/local/bin/bandwidth_check
wget --no-cache https://raw.githubusercontent.com/adrian2x/squid-bandwidth-script/master/squidaccess.sql

sudo mkdir /var/cache/squid
sudo chown -R proxy:proxy /var/cache/squid

echo "Setting up client profile..."
key=$(openssl rand -base64 32)
read -p "Enter a new username for client: " client_name
sudo htpasswd -bB /etc/squid/.squid_passwd "$client_name" "$key"

echo "Configuring firewall rules"
PORT=10000
sudo ufw allow ${PORT}/tcp
sudo iptables -I INPUT -m state --state NEW -p tcp --dport ${PORT} -j ACCEPT
ip6tables -A INPUT -p icmpv6 -j ACCEPT
ip6tables -A FORWARD -p icmpv6 -j ACCEPT
sudo netfilter-persistent save
sudo firewall-cmd --zone=trusted --permanent --add-port=${PORT}/tcp
sudo firewall-cmd --zone=public --permanent --add-port=${PORT}/tcp
sudo firewall-cmd --reload

# configure fail2ban to lock out brute force attacks
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
sudo service fail2ban restart

# vim /etc/iptables/rules.v4
# -A IN_public_allow -p udp -m tcp --dport ${PORT} -m conntrack --ctstate NEW,UNTRACKED -j ACCEPT
sudo echo "-A IN_public_allow -p udp -m tcp --dport ${PORT} -m conntrack --ctstate NEW,UNTRACKED -j ACCEPT
" >> /etc/iptables/rules.v4

echo "Setting up bandwidth quota..."
mysql -uroot -proot -e "CREATE USER 'squidaccess'@'localhost' IDENTIFIED BY 'Squidaccess 2021';"
mysql -uroot -proot -e "CREATE DATABASE squidaccess;"
mysql -uroot -proot -e "GRANT ALL PRIVILEGES ON squidaccess.* TO 'squidaccess'@'localhost';"
mysql squidaccess < squidaccess.sql

sudo touch /etc/squid/bandwidth_rules
sudo echo "${client_name}   100gb/m
" >> /etc/squid/bandwidth_rules

/usr/local/bin/bandwidth_calculate /etc/squid/bandwidth_rules

sudo systemctl restart squid

# start squid on reboot
sudo systemctl start squid.service
sudo systemctl enable squid.service

# prevent auto updates for squid
sudo dpkg --get-selections | grep squid
sudo apt-mark hold squid squid-common squid-dbg

echo "Done! Use ${client_name} and ${key}"
