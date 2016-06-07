if [ -z "$2" ]
  then
    scp -oStrictHostKeyChecking=no -i central_server_key.pem root@10.99.109.129:gold_images/svmp_data_disk.qcow2 $1.qcow2
 else
    scp -oStrictHostKeyChecking=no -i central_server_key.pem root@10.99.109.129:user_disks/$1.qcow2 .
fi


scp -oStrictHostKeyChecking=no -i central_server_key.pem root@10.99.109.129:gold_images/svmp_data_disk.qcow2 raghavb1@gmail.com.qcow2


cat <<EOF > network_config.xml
<network>
  <name>svmp</name>
  <forward mode='nat'>
    <nat>
      <port start='1024' end='65535'/>
    </nat>
  </forward>

  <bridge name='virbr100'  stp='on' delay='0'/>
  <ip address='192.168.122.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='192.168.122.58' end='192.168.122.58'/>
    </dhcp>
  </ip>
</network>
EOF


cat <<EOF > data_disk.xml
<disk type='file' device='disk'>
      <driver name='qemu' type='qcow2'/>
      <source file='/root/raghavb1@gmail.com.qcow2'/>
      <target dev='vdb' bus='virtio'/>   
      <alias name='virtio-disk1'/>
    </disk>
EOF

sleep 5s

virsh destroy svmp_vbox
virsh undefine svmp_vbox
virsh  net-destroy default
virsh  net-destroy svmp

virsh net-create network_config.xml 

virt-install -n svmp_vbox -r 6000 --os-type=linux --disk svmp_system_disk.qcow2,format=qcow2,device=disk,bus=virtio -w bridge=virbr100,model= --vnc --noautoconsole --import --vcpus 2 --hvm  --accelerate
virsh attach-device svmp_vbox data_disk.xml



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

virsh destroy svmp_vbox
virsh undefine svmp_vbox
virsh  net-destroy default
virsh  net-destroy svmp

virsh net-create network_config.xml 

virt-install -n svmp_vbox -r 6000 --os-type=linux --disk svmp_system_disk.qcow2,format=qcow2,device=disk,bus=virtio -w bridge=virbr100,model= --vnc --noautoconsole --import --vcpus 2 --hvm  --accelerate
virsh attach-device svmp_vbox data_disk.xml


echo USERS > USERS


