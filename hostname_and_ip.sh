export my_hostname=""     # edit node name here
export my_ip_suffix=""    # edit ip suffix her, inc by 1

echo "+--------------------------------+"
echo "|    Changing hostname and ip    |" 
echo "+--------------------------------+"
echo "Project:   MySQL Cluster"
echo "Host:      ${my_hostname}"
echo "IP:        192.168.205.${my_ip_suffix}"

if [ "$(id -u)" -ne 0 ];
  then echo "Please run script as root."
  exit 1
fi

if [ -z "${my_hostname}" ] ; then echo "Variable my_hostname not set!" ; fi
if [ -z "${my_ip_suffix}" ] ; then echo "Variable my_ip_suffix not set!" ; fi

echo "-------------------------"
echo "- Editing local IP address"
sudo /bin/sed -i "s/192.168.205.51/192.168.205.${my_ip_suffix}/g" /etc/network/interfaces

# local hosts table can have more or less hosts, here only 3 set
echo "-------------------------"
echo "- Editing lokal hosts table"
sudo tee /etc/hosts <<EOF
127.0.0.1 localhost
192.168.205.31 cluster1.itsdomain.local xxxx    # replace xxxx with hostname
192.168.205.32 cluster2.itsdomain.local xxxx    # replace xxxx with hostname
192.168.205.33 cluster3.itsdomain.local xxxx    # replace xxxx with hostname
EOF

echo "-------------------------"
echo "- Editing hostname"
sudo tee /etc/hostname <<EOF
${my_hostname}
EOF

echo "-------------------------"
echo "Editing done!"
echo ""
echo "!!!---!!!---!!!---!!!---!!!---"
echo " VM will restart in 5 seconds "
echo "!!!---!!!---!!!---!!!---!!!---"

/sbin/reboot
