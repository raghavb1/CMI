#argument1 - the ip address of user server
#argument2 - the id of user_volume

scp -oStrictHostKeyChecking=no -i central_server_key.pem root@$1:$2.qcow2 user_disks/
echo UPLOAD > UPLOAD
scp -oStrictHostKeyChecking=no -i central_server_key.pem UPLOAD root@$1:
