[managers]
manager ansible_host=${manager_ip} ansible_user=${ansible_user} ansible_ssh_private_key_file=${private_key_path}/manager/virtualbox/private_key

[workers]
worker1 ansible_host=${worker1_ip} ansible_user=${ansible_user} ansible_ssh_private_key_file=${private_key_path}/worker1/virtualbox/private_key
worker2 ansible_host=${worker2_ip} ansible_user=${ansible_user} ansible_ssh_private_key_file=${private_key_path}/worker2/virtualbox/private_key

[swarm:children]
managers
workers

[swarm:vars]
ansible_python_interpreter=/usr/bin/python3
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
