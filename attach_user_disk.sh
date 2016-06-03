if [ -z "$2" ]
  then
    scp -oStrictHostKeyChecking=no -i central_server_key.pem root@10.99.109.129:gold_images/svmp_data_disk.qcow2 $1.qcow2
 else
    scp -oStrictHostKeyChecking=no -i central_server_key.pem root@10.99.109.129:user_disks/$1.qcow2 .
fi

scp -oStrictHostKeyChecking=no -i central_server_key.pem root@10.99.109.129:gold_images/svmp_data_disk.qcow2 .

cat <<EOF > data_disk.xml
<disk type='file' device='disk'>
      <driver name='qemu' type='qcow2'/>
      <source file='/root/svmp_data_disk.qcow2'/>
      <target dev='vdb' bus='virtio'/>   
      <alias name='virtio-disk1'/>
    </disk>
EOF

sleep 2s

virsh attach-device svmp_vbox data_disk.xml

sleep 10s

sudo iptables -P INPUT ACCEPT
sudo iptables -P FORWARD ACCEPT
sudo iptables -P OUTPUT ACCEPT

sudo iptables -t nat -F
sudo iptables -t mangle -F
sudo iptables -F
sudo iptables -X

sudo iptables -A PREROUTING -t nat -i bond0 -p tcp --dport 8001 -j DNAT --to 192.168.122.58:8001

sudo iptables -A FORWARD -p tcp -d 192.168.122.58 --dport 8001 -j ACCEPT

sudo iptables -t nat -A POSTROUTING -o bond0 -j MASQUERADE

echo USERS > USERS


