#!bin/bash
# Apache Web Server User Data Script
yum -q -y install httpd mod_ssl
echo "MY Web Server" > /var/www/html/index.html
syttemctl enable --now httpd
