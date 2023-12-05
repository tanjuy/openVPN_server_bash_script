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




# System update and To install OpenVPN and Easy-RSA
# Easy-RSA is a public key infrastructure (PKI) management tool
echo "${yellow}${bold} System will be updated also install openvpn  and easy-rsa ;) $normal"
sleep 1
sudo apt update
sudo apt install openvpn easy-rsa


read -p "Enter a target user(i.e: tanju): " user
read -p "Enter a target IP(i.e: 192.168.1.5): " IP
ssh-copy-id -i ~/.ssh/id_rsa.pub $user@$IP

ssh -i ~/.ssh/id_rsa.pub $user@$IP "git clone https://github.com/tanjuy/Certificate_Authority_Server_Script.git" 
ssh -i ~/.ssh/id_rsa.pub $user@$IP "bash Certificate_Authority_Server_Script/Certificate_Authority_Server.sh" 

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

# To use this directory to create symbolic links pointing to the easy-rsa package files that we’ve installed in the previous step.
:<< test_command_alternative
if [[    # ------------------------------->   This is same as below if [  ] that is, test command
        -h "$easy_rsa/easyrsa" &&
        -L "$easy_rsa/openssl-easyrsa.cnf"
   ]]; then
test_command_alternative

if [ -h "$easy_rsa/easyrsa" -a -h "$easy_rsa/openssl-easyrsa.cnf" ]; then
        echo "A symlink have already created with $easy_rsa"
else
        ln -s /usr/share/easy-rsa/* ${easy_rsa}
        sleep 1
        echo "/usr/share/easy-rsa/*   ------>   ${easy_rsa} (symlinked)"
fi

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
# read -p 'Write "nopass" for no-password or just press enter: ' nop
$easy_rsa/easyrsa gen-req $CN nopass              # For example $1 server

sudo cp -v $easy_rsa/pki/private/$CN.key /etc/openvpn/server/

# Step 4;
# Once the CA validates and relays the certificate back to the OpenVPN server, clients that trust your CA will be
# able to trust the OpenVPN server as well.
# use SCP or another transfer method to copy the server.req certificate request to the CA server for signing:

echo "${cyan}$CN.req ----> $user@$IP:/tmp${normal}"
sleep 3
scp -i ~/.ssh/id_rsa.pub $easy_rsa/pki/reqs/$CN.req $user@$IP:/tmp

ssh -i ~/.ssh/id_rsa.pub $user@$IP "bash ${easy_rsa}/easyrsa import-req /tmp/$CN.req $CN"
ssh -i ~/.ssh/id_rsa.pub $user@$IP "cat << EOF | bash ${easy_rsa}/easyrsa sign-req $CN $CN yes EOF"

# pki yolu konrol edilmelidir!!!!!!!!!!!!!!!!!!!
scp -i ~/.ssh/id_rsa.pub $user@$IP:easy_rsa/pki/issued/$CN.crt /tmp
scp -i ~/.ssh/id_rsa.pub $user@$IP:easy_rsa/pki/ca.crt /tmp 

sudo cp /tmp/{$CN.crt,ca.crt} /etc/openvpn/server



