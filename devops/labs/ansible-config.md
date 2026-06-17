Below is the **simplest Ansible configuration management setup** in **GCP Cloud Shell**:

Architecture:

```text
Cloud Shell
   |
   | creates 3 VMs
   v
ansible-master
   |
   | SSH private IP
   v
ansible-slave-1
ansible-slave-2
```

We will configure both slave servers using Ansible from the master server.

---

# 1. Set basic variables in Cloud Shell

Run this in **Google Cloud Shell**:

```bash
export PROJECT_ID="$(gcloud config get-value project)"
export REGION="$(gcloud config get-value compute/region)"
export ZONE="$(gcloud config get-value compute/zone)"

export MASTER_NAME="ansible-master"
export SLAVE1_NAME="ansible-slave-1"
export SLAVE2_NAME="ansible-slave-2"

export MACHINE_TYPE="e2-micro"
export IMAGE_FAMILY="ubuntu-2204-lts"
export IMAGE_PROJECT="ubuntu-os-cloud"
```

Check values:

```bash
echo $PROJECT_ID
echo $REGION
echo $ZONE
```

If `REGION` or `ZONE` is empty, set them:

```bash
export REGION="asia-south1"
export ZONE="asia-south1-a"

gcloud config set compute/region $REGION
gcloud config set compute/zone $ZONE
```

---

# 2. Enable Compute Engine API

```bash
gcloud services enable compute.googleapis.com --project=$PROJECT_ID
```

---

# 3. Create SSH key for Ansible user

```bash
ssh-keygen -t ed25519 -f ~/.ssh/ansible_gcp_key -N "" -C "ansible"
```

Create metadata file:

```bash
echo "ansible:$(cat ~/.ssh/ansible_gcp_key.pub)" > /tmp/ansible-ssh-key.txt
```

---

# 4. Create Ansible master and 2 slave VMs

This will use the **default VPC**.

```bash
gcloud compute instances create $MASTER_NAME $SLAVE1_NAME $SLAVE2_NAME \
  --project=$PROJECT_ID \
  --zone=$ZONE \
  --machine-type=$MACHINE_TYPE \
  --image-family=$IMAGE_FAMILY \
  --image-project=$IMAGE_PROJECT \
  --boot-disk-size=10GB \
  --network=default \
  --tags=ansible-lab \
  --metadata=enable-oslogin=FALSE \
  --metadata-from-file ssh-keys=/tmp/ansible-ssh-key.txt
```

---

# 5. Create firewall rule for SSH and HTTP

SSH is required for Ansible.

HTTP is required because we will install Nginx as a simple example.

```bash
gcloud compute firewall-rules create ansible-lab-allow-ssh-http \
  --project=$PROJECT_ID \
  --network=default \
  --allow=tcp:22,tcp:80 \
  --source-ranges=0.0.0.0/0 \
  --target-tags=ansible-lab
```

If rule already exists, ignore the error.

---

# 6. Get IP addresses

```bash
export MASTER_EXTERNAL_IP=$(gcloud compute instances describe $MASTER_NAME \
  --zone=$ZONE \
  --format='get(networkInterfaces[0].accessConfigs[0].natIP)')

export SLAVE1_INTERNAL_IP=$(gcloud compute instances describe $SLAVE1_NAME \
  --zone=$ZONE \
  --format='get(networkInterfaces[0].networkIP)')

export SLAVE2_INTERNAL_IP=$(gcloud compute instances describe $SLAVE2_NAME \
  --zone=$ZONE \
  --format='get(networkInterfaces[0].networkIP)')

export SLAVE1_EXTERNAL_IP=$(gcloud compute instances describe $SLAVE1_NAME \
  --zone=$ZONE \
  --format='get(networkInterfaces[0].accessConfigs[0].natIP)')

export SLAVE2_EXTERNAL_IP=$(gcloud compute instances describe $SLAVE2_NAME \
  --zone=$ZONE \
  --format='get(networkInterfaces[0].accessConfigs[0].natIP)')
```

Check:

```bash
echo "Master External IP: $MASTER_EXTERNAL_IP"
echo "Slave 1 Internal IP: $SLAVE1_INTERNAL_IP"
echo "Slave 2 Internal IP: $SLAVE2_INTERNAL_IP"
echo "Slave 1 External IP: $SLAVE1_EXTERNAL_IP"
echo "Slave 2 External IP: $SLAVE2_EXTERNAL_IP"
```

---

# 7. Copy SSH private key to Ansible master

```bash
scp -i ~/.ssh/ansible_gcp_key \
  -o StrictHostKeyChecking=no \
  ~/.ssh/ansible_gcp_key \
  ansible@$MASTER_EXTERNAL_IP:/home/ansible/.ssh/id_ed25519
```

Fix permission:

```bash
ssh -i ~/.ssh/ansible_gcp_key \
  -o StrictHostKeyChecking=no \
  ansible@$MASTER_EXTERNAL_IP \
  "chmod 600 /home/ansible/.ssh/id_ed25519"
```

---

# 8. Install Ansible on master server

```bash
ssh -i ~/.ssh/ansible_gcp_key \
  ansible@$MASTER_EXTERNAL_IP
```

Now you are inside `ansible-master`.

Run:

```bash
sudo apt update
sudo apt install -y ansible python3
```

Check Ansible:

```bash
ansible --version
```

Exit master for now:

```bash
exit
```

---

# 9. Create Ansible project on master

From **Cloud Shell**, run this:

```bash
ssh -i ~/.ssh/ansible_gcp_key ansible@$MASTER_EXTERNAL_IP << EOF
mkdir -p /home/ansible/ansible-lab
cat > /home/ansible/ansible-lab/inventory.ini << INVENTORY
[slaves]
$SLAVE1_NAME ansible_host=$SLAVE1_INTERNAL_IP
$SLAVE2_NAME ansible_host=$SLAVE2_INTERNAL_IP

[all:vars]
ansible_user=ansible
ansible_ssh_private_key_file=/home/ansible/.ssh/id_ed25519
ansible_python_interpreter=/usr/bin/python3
INVENTORY

cat > /home/ansible/ansible-lab/ansible.cfg << CONFIG
[defaults]
inventory = inventory.ini
host_key_checking = False
private_key_file = /home/ansible/.ssh/id_ed25519
remote_user = ansible
CONFIG
EOF
```

---

# 10. Create simple configuration management playbook

This playbook will do configuration management on both slaves:

It will:

1. Update apt cache
2. Install Nginx
3. Start and enable Nginx
4. Create a custom webpage
5. Create a common config file

Run from **Cloud Shell**:

```bash
ssh -i ~/.ssh/ansible_gcp_key ansible@$MASTER_EXTERNAL_IP << 'EOF'
cat > /home/ansible/ansible-lab/configure-slaves.yml << 'PLAYBOOK'
---
- name: Simple configuration management for GCP slave servers
  hosts: slaves
  become: yes

  tasks:
    - name: Update apt package cache
      apt:
        update_cache: yes

    - name: Install nginx web server
      apt:
        name: nginx
        state: present

    - name: Start and enable nginx
      service:
        name: nginx
        state: started
        enabled: yes

    - name: Create common configuration file
      copy:
        dest: /etc/ansible-managed.conf
        content: |
          This server is managed by Ansible.
          Hostname: {{ inventory_hostname }}
          Managed at: {{ ansible_date_time.iso8601 }}

    - name: Create custom nginx homepage
      copy:
        dest: /var/www/html/index.html
        content: |
          <html>
            <head>
              <title>Ansible Configured Server</title>
            </head>
            <body>
              <h1>Hello from {{ inventory_hostname }}</h1>
              <p>This server was configured using Ansible.</p>
              <p>Managed by ansible-master in GCP.</p>
            </body>
          </html>

    - name: Restart nginx
      service:
        name: nginx
        state: restarted
PLAYBOOK
EOF
```

---

# 11. Test Ansible connection from master to slaves

```bash
ssh -i ~/.ssh/ansible_gcp_key ansible@$MASTER_EXTERNAL_IP
```

Inside master:

```bash
cd ~/ansible-lab
ansible all -m ping
```

Expected output:

```text
ansible-slave-1 | SUCCESS => {
    "ping": "pong"
}

ansible-slave-2 | SUCCESS => {
    "ping": "pong"
}
```

---

# 12. Run the configuration management playbook

Inside master:

```bash
cd ~/ansible-lab
ansible-playbook configure-slaves.yml
```

Expected output:

```text
PLAY RECAP
ansible-slave-1 : ok=6 changed=5 failed=0
ansible-slave-2 : ok=6 changed=5 failed=0
```

---

# 13. Verify from browser or Cloud Shell

From Cloud Shell:

```bash
curl http://$SLAVE1_EXTERNAL_IP
curl http://$SLAVE2_EXTERNAL_IP
```

Expected output:

```html
<h1>Hello from ansible-slave-1</h1>
```

and

```html
<h1>Hello from ansible-slave-2</h1>
```

You can also open these in browser:

```text
http://SLAVE1_EXTERNAL_IP
http://SLAVE2_EXTERNAL_IP
```

---

# 14. Final folder structure on Ansible master

```text
/home/ansible/ansible-lab
├── ansible.cfg
├── inventory.ini
└── configure-slaves.yml
```

---

# 15. Useful daily commands

SSH to Ansible master:

```bash
ssh -i ~/.ssh/ansible_gcp_key ansible@$MASTER_EXTERNAL_IP
```

Ping all slaves:

```bash
cd ~/ansible-lab
ansible all -m ping
```

Run playbook:

```bash
cd ~/ansible-lab
ansible-playbook configure-slaves.yml
```

Run command on all slaves:

```bash
ansible all -m shell -a "hostname && uptime"
```

Check Nginx status:

```bash
ansible all -m shell -a "systemctl status nginx --no-pager"
```

---

# 16. Cleanup command

When your practice is done, delete all 3 VMs:

```bash
gcloud compute instances delete $MASTER_NAME $SLAVE1_NAME $SLAVE2_NAME \
  --zone=$ZONE \
  --quiet
```

Delete firewall rule:

```bash
gcloud compute firewall-rules delete ansible-lab-allow-ssh-http --quiet
```

---

This is your simple Ansible configuration management setup:

```text
ansible-master
   |
   | manages using SSH
   v
ansible-slave-1
ansible-slave-2
```

The master controls both slaves and installs/configures Nginx automatically using one playbook.
