#!/usr/bin/env bash

# Variables;
easy_rsa="/home/$USER/easy-rsa"

# To color font
if [ -t 1 ]; then    # if terminal
  ncolors=$(which tput > /dev/null && tput colors)  # support color
  # if test -n "$ncolors" && [ $ncolors -ge 8 ]; then
  if [ -n "$ncolors" ] && [ $ncolors -ge 8 ]; then  # bir önceki satırın aynısı
    termCols=$(tput cols)      # termanal genişliğini verecektir
    bold=$(tput bold)          # terminal yazısını bold yapar
    underline=$(tput smul)     # terminal yazısının altını çizer
    standout=$(tput smso)      # terminal'de arka temaları tersine çevirir
    normal=$(tput sgr0)        # terminal'li başlangıç değerine döndürür
    black="$(tput setaf 0)"    # terminal yazısını siyah yapar
    red="$(tput setaf 1)"      # terminal yazısını kırmızı yapar
    green="$(tput setaf 2)"    # terminal yazısını yeşil yapar
    yellow="$(tput setaf 3)"   # terminal yazısını sarı yapar
    blue="$(tput setaf 4)"     # terminal yazısını mavi yapar
    magenta="$(tput setaf 5)"  # terminal yazısını magenta yapar
    cyan="$(tput setaf 6)"     # terminal yazısını cyan yapar
    white="$(tput setaf 7)"    # terminal yazısını beyaz yapar
  fi
fi


echo $easy_rsa


# System update and To install OpenVPN and Easy-RSA
# Easy-RSA is a public key infrastructure (PKI) management tool
echo "${yellow}${bold} System will be updated also install openvpn  and easy-rsa ;) $normal"
sleep 1
sudo apt update
sudo apt install openvpn easy-rsa


# To create a new directory on the OpenVPN Server
echo 'creating the easy-rsa directory...'
sleep 1
if [ -d "$easy_rsa" ]; then
	echo "$easy_rsa have already existed!"
else 
	mkdir $easy_rsa
	echo "$easy_rsa created!"
fi
# To create a symlink from the easyrsa script that the package installed into the ~/easy-rsa directory
sleep 1
ln -s /usr/share/easy-rsa/* $easy_rsa

# The directory’s owner is your non-root sudo user and restrict access to that user
sudo chown $USER $easy_rsa
chmod 700 $easy_rsa

# To create a Public Key Infrastructure (PKI) on the OpenVPN server so that you can request and manage TLS
# certificates for clients and other servers that will connect to your VPN.

# To build a PKI directory on your OpenVPN server
# Step 2

sed 's/^#set_var EASYRSA_ALGO\t\trsa/set_var EASYRSA_ALGO\t\t"ec"/' $easy_rsa/vars.example > $easy_rsa/vars
sed -i 's/^#set_var EASYRSA_DIGEST\t\t"sha256"/set_var EASYRSA_DIGEST\t\t"sha512"/' $easy_rsa/vars 

cd $easy_rsa
pwd
bash $easy_rsa/easyrsa init-pki

# Step 3
# Creating an OpenVPN Server Certificate Request and Private Key
# Run to the easyrsa with the gen-req option followed by a Common Name (CN) for the machine.
read -p 'OpenVPN Server’s CN: ' CN
read -p 'Write "nopass" for no-password or just press enter: ' nop
$easy_rsa/easyrsa gen-req $CN $nop              # For example $1 server

sudo cp -v $easy_rsa/pki/private/server.key /etc/openvpn/server/