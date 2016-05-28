if [ -z "$1" ]
  then
    $1 = "svmp_data_disk"
    scp -oStrictHostKeyChecking=no -i central_server_key.pem root@10.99.109.129:gold_images/svmp_data_disk.qcow2 .
 else
    scp -oStrictHostKeyChecking=no -i central_server_key.pem root@10.99.109.129:user_disks/$1.qcow2 .
fi

cat <<EOF > data_disk.xml
<disk type='file' device='disk'>
      <driver name='qemu' type='qcow2'/>
      <source file='/root/$1.qcow2'/>
      <target dev='vdb' bus='virtio'/>   
      <alias name='virtio-disk1'/>
    </disk>
EOF

virsh attach-device svmp_vbox data_disk.xml


