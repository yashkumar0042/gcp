Below is a **complete from-scratch GCP Cloud Shell setup**.

GCP `gcloud compute ssh` can auto-create/manage SSH keys for VM access, and Ansible will connect over SSH to managed nodes. ([Google Cloud Documentation][1])

## 1. Set variables in Cloud Shell

```bash
PROJECT_ID=$(gcloud config get-value project)
ZONE="asia-south1-a"
MACHINE_TYPE="e2-micro"

MASTER="ansible-master"
SLAVE1="ansible-slave-1"
SLAVE2="ansible-slave-2"
USER_NAME=`whoami'
```

## 2. Create 3 Ubuntu VMs

```bash
gcloud compute instances create $MASTER $SLAVE1 $SLAVE2 \
  --project=$PROJECT_ID \
  --zone=$ZONE \
  --machine-type=$MACHINE_TYPE \
  --image-family=ubuntu-2204-lts \
  --image-project=ubuntu-os-cloud \
  --tags=ansible-lab,http-server
```

## 3. Allow SSH and HTTP firewall

```bash
gcloud compute firewall-rules create allow-ssh-ansible-lab \
  --allow tcp:22 \
  --target-tags=ansible-lab \
  --description="Allow SSH for Ansible lab"

gcloud compute firewall-rules create allow-http-ansible-lab \
  --allow tcp:80 \
  --target-tags=http-server \
  --description="Allow HTTP Apache access"
```

## 4. Get slave private IPs

```bash
SLAVE1_IP=$(gcloud compute instances describe $SLAVE1 --zone=$ZONE --format='get(networkInterfaces[0].networkIP)')
SLAVE2_IP=$(gcloud compute instances describe $SLAVE2 --zone=$ZONE --format='get(networkInterfaces[0].networkIP)')

echo $SLAVE1_IP
echo $SLAVE2_IP
```

## 5. SSH into Ansible master

```bash
gcloud compute ssh $MASTER --zone=$ZONE
```

Now run everything below **inside ansible-master**.

## 6. Install Ansible on master

```bash
sudo apt update
sudo apt install -y ansible python3-pip
ansible --version
```

Ansible uses modules like `apt` to manage Ubuntu packages. ([docs.ansible.com][2])

## 7. Generate SSH key on master

```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/ansible_key -N ""
cat ~/.ssh/ansible_key.pub
```

Copy the full public key output.

## 8. Add master public key to both slaves

Exit master:

```bash
exit
```

From **Cloud Shell**, run:

```bash
gcloud compute ssh $SLAVE1 --zone=$ZONE
```

Inside slave 1:

```bash
mkdir -p ~/.ssh
nano ~/.ssh/authorized_keys
```

Paste the public key from master, save, then:

```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
exit
```

Repeat for slave 2:

```bash
gcloud compute ssh $SLAVE2 --zone=$ZONE
```

Inside slave 2:

```bash
mkdir -p ~/.ssh
nano ~/.ssh/authorized_keys
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
exit
```

## 9. Go back to master

```bash
gcloud compute ssh $MASTER --zone=$ZONE
```

## 10. Create Ansible project

```bash
mkdir -p ~/ansible-lab
cd ~/ansible-lab
```

## 11. Create inventory file

```bash
nano inventory.yaml
```

Paste this, replacing IPs:

```yaml
all:
  children:
    webservers:
      hosts:
        slave1:
          ansible_host: SLAVE1_PRIVATE_IP
          ansible_user: YOUR_USERNAME
          ansible_ssh_private_key_file: ~/.ssh/ansible_key
        slave2:
          ansible_host: SLAVE2_PRIVATE_IP
          ansible_user: YOUR_USERNAME
          ansible_ssh_private_key_file: ~/.ssh/ansible_key
```

Check username on master:

```bash
whoami
```

Use same username because GCP creates the same Linux user on VMs when using `gcloud compute ssh`.

## 12. Test SSH manually from master

```bash
ssh -i ~/.ssh/ansible_key YOUR_USERNAME@SLAVE1_PRIVATE_IP
exit

ssh -i ~/.ssh/ansible_key YOUR_USERNAME@SLAVE2_PRIVATE_IP
exit
```

## 13. Test Ansible ping

```bash
ansible all -i inventory.yaml -m ping
```

Expected:

```text
slave1 | SUCCESS => {"ping": "pong"}
slave2 | SUCCESS => {"ping": "pong"}
```

## 14. Create Apache playbook

```bash
nano apache-install.yaml
```

Paste:

```yaml
---
- name: Install and start Apache on slave servers
  hosts: webservers
  become: yes

  tasks:
    - name: Update apt cache
      ansible.builtin.apt:
        update_cache: yes

    - name: Install Apache2
      ansible.builtin.apt:
        name: apache2
        state: present

    - name: Start and enable Apache2
      ansible.builtin.service:
        name: apache2
        state: started
        enabled: yes

    - name: Create custom index.html
      ansible.builtin.copy:
        dest: /var/www/html/index.html
        content: |
          <h1>Apache installed using Ansible</h1>
          <p>Server: {{ inventory_hostname }}</p>
```

## 15. Run playbook

```bash
ansible-playbook -i inventory.yaml apache-install.yaml
```

## 16. Verify Apache

```bash
ansible webservers -i inventory.yaml -m shell -a "systemctl status apache2 --no-pager"
```

From Cloud Shell, get external IPs:

```bash
gcloud compute instances list
```

Open:

```text
http://SLAVE1_EXTERNAL_IP
http://SLAVE2_EXTERNAL_IP
```

## Cleanup commands

```bash
gcloud compute instances delete ansible-master ansible-slave-1 ansible-slave-2 --zone=asia-south1-a

gcloud compute firewall-rules delete allow-ssh-ansible-lab allow-http-ansible-lab
```

[1]: https://docs.cloud.google.com/sdk/gcloud/reference/compute/ssh?utm_source=chatgpt.com "gcloud compute ssh | Google Cloud SDK"
[2]: https://docs.ansible.com/projects/ansible/latest/collections/ansible/builtin/apt_module.html?utm_source=chatgpt.com "ansible.builtin.apt module – Manages apt-packages"
