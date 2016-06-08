sudo apt-get -y install qemu-kvm libvirt-bin ubuntu-vm-builder bridge-utils virtinst android-tools-adb

cat <<EOF >> /etc/libvirt/qemu.conf
user='root'
group='root'
EOF

sudo service libvirt-bin restart

cat <<EOF > central_server_key.pem
-----BEGIN RSA PRIVATE KEY-----
MIIEpQIBAAKCAQEAvh98ZVUITudYzOsQBuV2pSH2+NF2dL8iQmyGGCqH+t0rxsBJ
M4tyPQYc55+kda+lCILToUMhcEDp+ww0pABLjhs1zgNIHIAnUUrHrBdvd31yMp2n
X74Gdubk1KV+jzGwiVjg8nFCkoSwOPBvwtpdMdvF6Yh05Z0RG0wl1wenQeCm/wlx
+K7K6hoAu4P2gYAUXrhnVux87TCcz7gfYmjcaK31UhfN3IgpUxOZcEXxwXykuCCM
4IH49Sezuu5vjP2mumsHR0/AnffdA4C7wlS7m0gFxzqUv4G7IaONa6l+QDf0eUPx
EHsXADSbV/XmhMWmaDFJHaiM5IOSRQNfwiQzBQIDAQABAoIBAQCKcc0Y0QnCw05z
sfwyuWdjKk94srbqnsAo1HP1JwtsDyAwk5b6dOHUNB5aQHL2y9eGUhYfiQ3Re0Om
7yVqA1kBeyj8AoHBV0TKOoUZ+NrPjUbaOtlFq89zSAF8I6L8TPe7nD/566XJodvd
KqCHqJFSnDILM7XD+lMZqKKpacZO/jBWUnNDF1GavYIZSOOmTuz1xSko4EZl9otF
2wXXxEeehY+AOErEhddaF+2k4yi/Iu6stVk0tOYVdPCbdlfu39R5ghxq/wX4OTDV
dG/Nl3OMM6G08SGPPx0zkMeir3QJbaGCSpucuTf32kR+ROlbTzvP3XQ4DYRhW7e4
C9dKP4VBAoGBAPO9bmNNn/tCr1XQncYImiR/6MPlNmnc/lis1+k/f9pfSk6P8lVF
zSt53R3+INh7r5CWyEelD4JpwJhUehJhoybiSP2Hv5wsh/YxqW4ARUO4EIfGtpOu
bsugARE0NtCcrR0vCyBigTfdjWk9Th4fi2kNUXuTwTkTvf08H4J7m8sxAoGBAMev
pP6DbyDsMm3mXy0G/sGRQ6b+we2WSa4VjKHQnFAI1fV8YohnWYoKCB68YIP7nrtw
YzKtRXwP/0UnWAyR2asyV1EMw3fTBf6BQzico0UUMRfUpxg7qE6jb2kmP+QDDMku
qNqupcLe26KZ44mhzaIz/g/5Apz8LzngEJnJcwgVAoGBALoLlf7meX7oX705B7Tp
S/8gQyOECgy0StCU3hmEBqtAoQ9mgKrmJL1Sv5ztJVUY0+Ghti45p6T7465ijOsK
6+X6Q4yB2ZfzxbP+JD16p2QRU0zQOPxw4NE8yJPBLzX84YatKekGR2vFCPOTf9Uu
btM4/0E8fvh6QULSaZrHjxuBAoGAPqHtEpePJ7huKOJ1P95N0dEKczq9ARR+j8fa
kHaqUMA0vAcDsN0ZzJ5Q5bMYYs1tgEVEGAUZIkyyOLKaf3bP206y7I0gUlkyLB3H
Q959p5EpxNvCfWtY4zGIJGcG6zG5tPCZrd3RyEm2gk3afLTvlszQB5qHI05GUdTh
4Bq7pfECgYEA2kuYw5rqVQRUs25/JSb00EqbMCL5DYWBvzO6HJjBe/Bo79vdHyP/
jZtk0uKPCrt1VZAaN3OiYsLC9daBpCodmQkUeLacayEN/pqusWEpmZ4x/DAsgjN8
Aqg43Wjv+AEc+DVvMeeTjJ7qFAweRWfxoHZXJX2esqA9IhBcYp2/l1k=
-----END RSA PRIVATE KEY-----
EOF

chmod 400 central_server_key.pem

scp -oStrictHostKeyChecking=no -i central_server_key.pem root@10.99.109.129:gold_images/svmp_system_disk.qcow2 .

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

virsh destroy svmp_vbox
virsh undefine svmp_vbox
virsh  net-destroy default
virsh  net-destroy svmp

virsh net-create network_config.xml 

virt-install -n svmp_vbox -r 6000 --os-type=linux --disk svmp_system_disk.qcow2,format=qcow2,device=disk,bus=virtio -w bridge=virbr100,model= --vnc --noautoconsole --import --vcpus 2 --hvm  --accelerate


# virt-install -n svmp_vbox -r 2000 --os-type=linux --disk svmp_system_disk.qcow2,format=qcow2,device=disk,bus=virtio -w bridge=virbr100,model= --vnc --noautoconsole --import --vcpus 2 --hvm  --accelerate
#virsh attach-device svmp_vbox data_disk.xml
#sleep 60s

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

echo KVM > KVM
