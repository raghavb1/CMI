sudo apt-get -y install qemu-kvm libvirt-bin ubuntu-vm-builder bridge-utils virtinst

cat <<EOF >> oval_key.pem
-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEAtN1nuXVA8krDzh4FTozVyA8EcFOYtpfasECDf1D6BzOfZFdNswWMF/ffvRBX
D88bgPxcs2BZI58wERswomsC+NFm145vlGQBXc5tywwAdkmoNOngos6jDcVrlQ56uGEi4uNJl7u8
9PqyBWvypdVYb5hkp+B9lLl93dEhDPCQSm4sWTcW3UEuVLdeMdlw9zkSOrS9wfhbzYWGqnPPJ978
41GxVQrF20XQDUn4AyL9DkKPyognVDs8vXOnySWEOrW0BlP3Vym3dJhAGtFdWQ1EimWQ0qSAqL2E
HaW52Co/hdRTR30odtjqRN467OZpN08JXKuCS0RX4mTJ8lNVS68ikwIDAQABAoIBAQC0uKrlIGl1
8Qj4Ev1AgO84iPDpgE6O3OuSw9PhSruaqJVzAN1NrZRPesngs8waqtqTpxbF0dcgBfdUkHOnRwBg
OXTmnJeXkdnfrt38TpDDoVPnE273nzxEDWkzNpWfWMgwJ+YoLFph+4IYcsWxuJ02XPLu4Bz7l+FR
3J6GvHWhOAkmbNOn4KfbzMwTPzKCPOzd8AsXr0WCUZA1/Z1JrJi17kygPSEkU9Auv18booafEGUP
jj5nb8wbSNetGP3duhvQZgrQ7IsLrmHWwVRlL9bH6mBN2vs3Ou0+SW4+bFxSu4AQYQCaoJZ/Koyw
PYkzhWolHQDg2mjeiwj/Ax47nshJAoGBANixy1XC5DvVaNqMBM6zwK31OwIEt/1zZg0mFNkhwEF8
L5LVCg7c8hiQFCZ915aT4UTRbzwTAugebaZD3oXP2lnN3JRG2Oo8AIcH+ndZLtqszbWeOB0N+1uA
9bKUeo7ZeT4VGNtRkgc59rtvcXZ7lsjrxRDC8UG8POTpAz140rINAoGBANWr3KmD9awv2Acq/OOH
CWsO9vaoQtKls3V4AqxcJ/zcpYUe6J3P2oDUwrS7jZNnvZA68bt9BgsPSWv9jElCDD9rnrivaCLm
b+2gK+LHtf3YUaX/l5QjNzN0omADg00VbDDPA2/dkGiQwB3KNANa+Vy/AtszhOdZ4UtuqiuGDB8f
AoGAaL+JSyuqqEHBLeQBbun1eiHRJGijiCEAc9q0uUFXblBZruDMu+KSJM2A8Bpk3KUff+S9oIyQ
GySaXITyTDztj/uzZPnaYWAf4SY6LPcvbwWZavHQrjrUBqeQHYMou2Tk9t275kjIDjY2zuRQNLYJ
bZaK7E9P0DbuOLlql4yQTQECgYAFsUh1s7BN4BBvUHPgU+6qTYHC3IS7O/LmBEZ99Q6TrAU04Lft
zGXT3Nc7HWwOK0tfllJuXkxU6xlXqS+dnAbbgbB+1x19IIqG2CeTKSLuGl9Cfua46Z9E3aydxjov
SYzSWBGNX2fDgWe843AzTq8qC2S2Fk9KIpjf+5jJBA86nQKBgE5zo4rc4edXo6azGPHvfddd0C8J
sPX0RtefTAXX9ty11AY72brfsssMuZHZSo1rdm5srdwokSOn+VYXQx58Zj3nvXTb4+uOvTVCT+UO
xXYOsudR5+4rVuoYedud5Czu69nQCBZ5cniEWcCTYglB7DIswbY8FMlm7dHBldBsrrc6
-----END RSA PRIVATE KEY-----
EOF

chmod 400 oval_key.pem

scp -oStrictHostKeyChecking=no -i oval_key.pem ubuntu@54.68.24.31:/mnt/oval/svmp/asop/out/target/product/svmp/svmp_system_disk.img .

scp -oStrictHostKeyChecking=no -i oval_key.pem ubuntu@54.68.24.31:/mnt/oval/svmp/asop/out/target/product/svmp/svmp_data_disk.img .

cat <<EOF >> /etc/libvirt/qemu.conf
user='root'
group='root'
EOF

cat <<EOF >> data_disk.xml
<disk type='file' device='disk'>
      <driver name='qemu' type='raw'/>
      <source file='/root/svmp_data_disk.img'/>
      <target dev='vdb’ bus='virtio'/>
      <alias name='virtio-disk1'/>
    </disk>
EOF

sudo service libvirt-bin restart

virsh destroy svmp_vbox
virsh undefine svmp_vbox
virsh  net-destroy default
virsh  net-destroy svmp

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

virsh net-create network_config.xml 

virt-install -n svmp_vbox -r 4000 --os-type=linux --disk svmp_system_disk.img,device=disk,bus=virtio -w bridge=virbr100,model= --vnc --noautoconsole --import --vcpus 2 --hvm

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
