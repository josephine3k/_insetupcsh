#!/bin/bash
# Proxy Installer

rm -rf /etc/squid
yum remove squid -y
MYIP=$(wget -qO- ipv4.icanhazip.com);
yum update -y
yum install squid unzip -y
wget -O /etc/squid/squid.zip https://raw.githubusercontent.com/omayanrey/lnmp/master/auth/marielvpn/squid.zip &> /dev/null
cd /etc/squid
unzip squid.zip
rm -rf *zip
cd
ethernet=""
echo "************************************************************************************"
echo -e " Note: Your Network Interface is followed by the word \e[1;31m' dev '\e[0m"
echo " If the interface doesnt match openvpn will be connected but no internet access."
echo " Please choose or type properly"
echo "************************************************************************************"
echo ""
echo "Your Network Interface is:"
ip route | grep default
echo ""
echo "Ethernet:"
read ethernet
echo ""
clear
iptables -F; iptables -X; iptables -Z
iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o $ethernet -j MASQUERADE
iptables -t nat -A POSTROUTING -s 10.9.0.0/24 -o $ethernet -j MASQUERADE
iptables -t nat -A POSTROUTING -s 10.10.0.0/24 -o $ethernet -j MASQUERADE
iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -j SNAT --to $MYIP
iptables -t nat -A POSTROUTING -s 10.9.0.0/24 -j SNAT --to $MYIP
ptables -t nat -A POSTROUTING -s 10.10.0.0/24 -j SNAT --to $MYIP
iptables -A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -s 10.8.0.0/24 -j ACCEPT
iptables -A FORWARD -s 10.9.0.0/24 -j ACCEPT
iptables -A FORWARD -s 10.10.0.0/24 -j ACCEPT
iptables -A FORWARD -j REJECT
iptables -A INPUT -p tcp --dport 25 -j DROP
iptables -A INPUT -p udp --dport 25 -j DROP
clear

echo '' > /etc/squid/squid.conf
echo '# Recommended minimum configuration:
cache deny all
memory_pools off
dns_nameservers 208.67.222.222 208.67.222.220 8.8.8.8 8.8.4.4
half_closed_clients off

http_port 3128 transparent
http_port 8000 transparent
http_port 8080 transparent
http_port 8888 transparent

#########################
# Incoming and Outgoing #
#########################
acl incoming src $MYIP
acl outgoing dst $MYIP
http_access allow incoming
http_access allow outgoing

##################
# Allowed VPN IP #
##################
acl to_vpn dst "/etc/squid/iplist.txt"
http_access allow to_vpn

visible_hostname SVPN-Proxy

via off
forwarded_for off
request_header_access Allow allow all
request_header_access Authorization allow all
request_header_access WWW-Authenticate allow all
request_header_access Proxy-Authorization allow all
request_header_access Proxy-Authenticate allow all
request_header_access Cache-Control allow all
request_header_access Content-Encoding allow all
request_header_access Content-Length allow all
request_header_access Content-Type allow all
request_header_access Date allow all
request_header_access Expires allow all
request_header_access Host allow all
request_header_access If-Modified-Since allow all
request_header_access Last-Modified allow all
request_header_access Location allow all
request_header_access Pragma allow all
request_header_access Accept allow all
request_header_access Accept-Charset allow all
request_header_access Accept-Encoding allow all
request_header_access Accept-Language allow all
request_header_access Content-Language allow all
request_header_access Mime-Version allow all
request_header_access Retry-After allow all
request_header_access Title allow all
request_header_access Connection allow all
request_header_access Proxy-Connection allow all
request_header_access User-Agent allow all
request_header_access Cookie allow all
request_header_access All deny all
acl manager proto cache_object
acl localhost src 127.0.0.1/32 ::1
acl to_localhost dst 127.0.0.0/8 0.0.0.0/32 ::1

acl localnet src 10.0.0.0/8     # RFC1918 possible internal network
acl localnet src 172.16.0.0/12  # RFC1918 possible internal network
acl localnet src 192.168.0.0/16 # RFC1918 possible internal network
acl localnet src fc00::/7       # RFC 4193 local private network range
acl localnet src fe80::/10      # RFC 4291 link-local (directly plugged) machines
    
acl SSL_ports port 443
acl SSL_ports port 22
acl SSL_ports port 80
acl SSL_ports port 992
acl SSL_ports port 1194
acl SSL_ports port 995
acl SSL_ports port 5555
acl SSL_ports port 8080
acl SSL_ports port 8888
acl Safe_ports port 80          # http
acl Safe_ports port 21          # ftp
acl Safe_ports port 443         # https
acl Safe_ports port 70          # gopher
acl Safe_ports port 210         # wais
#acl Safe_ports port 1025-65535  # unregistered ports
acl Safe_ports port 280         # http-mgmt
acl Safe_ports port 488         # gss-http
acl Safe_ports port 591         # filemaker
acl Safe_ports port 777         # multiling http
acl Safe_ports port 3128
acl Safe_ports port 992
acl Safe_ports port 995
acl Safe_ports port 5555
acl Safe_ports port 1194
acl Safe_ports port 8080
acl Safe_ports port 8888
acl CONNECT method CONNECT

http_access allow manager localhost
http_access deny manager
http_access deny !Safe_ports
http_access deny CONNECT !SSL_ports

########################
# Block File Extension #
########################
acl blockfiles urlpath_regex -i "/etc/squid/extension.txt"
http_access deny blockfiles
http_access deny CONNECT blockfiles
http_reply_access deny blockfiles

##################
# Block adBlock ##
##################
acl myads_ignore dstdom_regex -i "/etc/squid/ad_block_ignore.txt"
http_access allow myads_ignore

acl myads dstdom_regex -i "/etc/squid/ad_block_custom.txt"
http_access deny myads
http_access deny CONNECT myads
http_reply_access deny myads

###########################
# Block Sony Playstation ##
###########################
acl deny_sony dstdomain "/etc/squid/sony-domains.txt"
http_access deny deny_sony
http_access deny CONNECT deny_sony
http_reply_access deny deny_sony

acl sonydeny dstdomain account.sonyentertainmentnetwork.com
acl sonydeny dstdomain auth.np.ac.playstation.net
acl sonydeny dstdomain auth.api.sonyentertainmentnetwork.com
acl sonydeny dstdomain auth.api.np.ac.playstation.net
acl sonydeny dstdomain playstation.net
acl sonydeny dstdomain sonyentertainmentnetwork.com
http_access deny sonydeny
http_access deny CONNECT sonydeny
http_reply_access deny sonydeny

##################
# Block torrent ##
##################
acl deny_torrent rep_mime_type ^application/x-bittorrent
acl deny_torrent rep_mime_type -i mime-type application/x-bittorrent
http_access deny deny_torrent
http_access deny CONNECT deny_torrent
http_reply_access deny deny_torrent
deny_info TCP_RESET deny_torrent

###########################
# Block 1025-65535 Ports ##
###########################
acl Denied_ports port 1025-65535 
http_access deny Denied_ports
http_access deny CONNECT Denied_ports

http_access allow localnet
http_access allow localhost
http_access allow incoming outgoing
http_access deny all

hierarchy_stoplist cgi-bin ?

refresh_pattern ^ftp:           1440    20%     10080
refresh_pattern ^gopher:        1440    0%      1440
refresh_pattern -i (/cgi-bin/|\?) 0     0%      0
refresh_pattern .               0       20%     4320
cache_effective_user squid
cache_effective_group squid

shutdown_lifetime 0 seconds'| sudo tee /etc/squid/squid.conf
chmod -R 755 /etc/squid
service iptables save
chkconfig squid on
service iptables start
/etc/init.d/squid start
rm -rf *sh
cat /dev/null > ~/.bash_history && history -c && history -w
