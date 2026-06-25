Below is a **complete Nagios lab on GCP VM instances** using:

**VM-1:** `nagios-server`
**VM-2:** `gcp-client-1`
**OS:** Ubuntu 22.04 / 24.04
**Monitoring:** Ping, SSH, HTTP, Disk, Load, Processes using NRPE.

Nagios Core 4 can be installed through Ubuntu packages using `nagios4` and `nagios-nrpe-plugin`, and the remote VM can run `nagios-nrpe-server`. Ubuntu’s own Nagios Core 4 guide also uses a two-server setup where one server monitors itself and another remote server. ([Ubuntu Community Hub][1])

---

## 1. Architecture

```text
Your Browser
    |
    | HTTP :80
    v
GCP VM 1: nagios-server
    |
    | NRPE :5666 over private IP
    v
GCP VM 2: gcp-client-1
```

Use **private IP** between Nagios server and client. Open Nagios web UI only to your public IP, not to the whole internet. GCP firewall rules can allow/deny traffic to VM instances based on port, protocol, target tags, and source ranges/tags. ([Google Cloud Documentation][2])

---

## 2. Create two GCP VM instances

Run from Cloud Shell or your local terminal with `gcloud` configured.

```bash
gcloud config set project YOUR_PROJECT_ID
```

Create Nagios server VM:

```bash
gcloud compute instances create nagios-server \
  --zone=asia-south1-a \
  --machine-type=e2-medium \
  --image-family=ubuntu-2204-lts \
  --image-project=ubuntu-os-cloud \
  --boot-disk-size=20GB \
  --tags=nagios-server
```

Create client VM:

```bash
gcloud compute instances create gcp-client-1 \
  --zone=asia-south1-a \
  --machine-type=e2-micro \
  --image-family=ubuntu-2204-lts \
  --image-project=ubuntu-os-cloud \
  --boot-disk-size=10GB \
  --tags=nagios-client
```

Get internal IPs:

```bash
gcloud compute instances list
```

Example:

```text
nagios-server internal IP: 10.160.0.2
gcp-client-1 internal IP: 10.160.0.3
```

---

## 3. Create GCP firewall rules

### Allow Nagios Web UI

Replace `YOUR_PUBLIC_IP/32` with your laptop/office public IP.

```bash
gcloud compute firewall-rules create allow-nagios-http \
  --network=default \
  --allow=tcp:80 \
  --source-ranges=YOUR_PUBLIC_IP/32 \
  --target-tags=nagios-server
```

For a temporary lab only, you can use:

```bash
--source-ranges=0.0.0.0/0
```

But avoid this in real setup.

### Allow NRPE from Nagios server to client

```bash
gcloud compute firewall-rules create allow-nrpe-from-nagios \
  --network=default \
  --allow=tcp:5666 \
  --source-tags=nagios-server \
  --target-tags=nagios-client
```

NRPE allows Nagios to execute plugins on remote Linux/Unix machines so you can monitor disk usage, CPU load, and other local metrics from the Nagios server. ([Nagios Exchange][3])

---

## 4. Install Nagios on `nagios-server`

SSH into Nagios server:

```bash
gcloud compute ssh nagios-server --zone=asia-south1-a
```

Install packages:

```bash
sudo apt update
sudo apt install -y software-properties-common
sudo add-apt-repository universe -y
sudo apt update

sudo apt install -y nagios4 nagios-nrpe-plugin monitoring-plugins apache2
```

During Postfix prompt, choose:

```text
No configuration
```

Create Nagios admin user:

```bash
sudo htdigest -c /etc/nagios4/htdigest.users "Nagios4" nagiosadmin
```

Set password, for example:

```text
nagiosadmin / YourPassword
```

Ubuntu’s guide uses this same `htdigest` command for creating the Nagios web user. ([Ubuntu Community Hub][1])

---

## 5. Enable Nagios web UI

Edit Nagios CGI config:

```bash
sudo nano /etc/nagios4/cgi.cfg
```

Find:

```text
use_authentication=0
```

Change to:

```text
use_authentication=1
```

Now enable Apache config:

```bash
sudo cp /etc/nagios4/apache2.conf /etc/apache2/sites-available/nagios4.conf
sudo a2ensite nagios4.conf
sudo systemctl reload apache2
sudo systemctl restart nagios4
```

Check services:

```bash
sudo systemctl status apache2
sudo systemctl status nagios4
```

Open in browser:

```text
http://NAGIOS_SERVER_EXTERNAL_IP/nagios4
```

Login:

```text
Username: nagiosadmin
Password: password_you_created
```

The default Ubuntu Nagios package exposes the UI using `/nagios4`, and the Apache alias can be changed later if needed. ([Ubuntu Community Hub][1])

---

## 6. Install NRPE on client VM

SSH into client:

```bash
gcloud compute ssh gcp-client-1 --zone=asia-south1-a
```

Install NRPE and plugins:

```bash
sudo apt update
sudo apt install -y nagios-nrpe-server monitoring-plugins nginx
```

I installed `nginx` only so we can test HTTP monitoring also.

Check NRPE service:

```bash
sudo systemctl status nagios-nrpe-server
```

Edit NRPE config:

```bash
sudo nano /etc/nagios/nrpe.cfg
```

Find:

```text
allowed_hosts=127.0.0.1,::1
```

Change it to include Nagios server private IP:

```text
allowed_hosts=127.0.0.1,::1,10.160.0.2
```

Replace `10.160.0.2` with your actual `nagios-server` internal IP.

Now add these commands at the bottom:

```text
command[check_root_disk]=/usr/lib/nagios/plugins/check_disk -w 20% -c 10% -p /
command[check_load]=/usr/lib/nagios/plugins/check_load -w 5,4,3 -c 10,6,4
command[check_total_procs]=/usr/lib/nagios/plugins/check_procs -w 150 -c 200
```

Restart NRPE:

```bash
sudo systemctl restart nagios-nrpe-server
sudo systemctl enable nagios-nrpe-server
```

Verify NRPE is listening:

```bash
sudo ss -lntp | grep 5666
```

Expected:

```text
LISTEN 0  ... 0.0.0.0:5666
```

Nagios plugins are executable checks used for things like websites, Linux servers, services, disk usage, CPU/load, and similar infrastructure metrics. ([Nagios Open Source][4])

---

## 7. Test NRPE from Nagios server

Go back to `nagios-server`:

```bash
gcloud compute ssh nagios-server --zone=asia-south1-a
```

Test NRPE connection:

```bash
/usr/lib/nagios/plugins/check_nrpe -H 10.160.0.3
```

Expected output:

```text
NRPE v4.x.x
```

Test disk check:

```bash
/usr/lib/nagios/plugins/check_nrpe -H 10.160.0.3 -c check_root_disk
```

Expected:

```text
DISK OK - free space...
```

Test load:

```bash
/usr/lib/nagios/plugins/check_nrpe -H 10.160.0.3 -c check_load
```

---

## 8. Configure Nagios to monitor client VM

On `nagios-server`, create command definition:

```bash
sudo nano /etc/nagios4/conf.d/check_nrpe_command.cfg
```

Paste:

```text
define command {
    command_name    check_nrpe
    command_line    /usr/lib/nagios/plugins/check_nrpe -H $HOSTADDRESS$ -c $ARG1$
}
```

Now create client config:

```bash
sudo nano /etc/nagios4/conf.d/gcp-client-1.cfg
```

Paste this and replace IP with your client internal IP:

```text
define host {
    use                     generic-host
    host_name               gcp-client-1
    alias                   GCP Client VM 1
    address                 10.160.0.3
    max_check_attempts      5
    check_period            24x7
    notification_interval   30
    notification_period     24x7
}

define service {
    use                     generic-service
    host_name               gcp-client-1
    service_description     PING
    check_command           check-host-alive
}

define service {
    use                     generic-service
    host_name               gcp-client-1
    service_description     SSH
    check_command           check_ssh
}

define service {
    use                     generic-service
    host_name               gcp-client-1
    service_description     HTTP
    check_command           check_http
}

define service {
    use                     generic-service
    host_name               gcp-client-1
    service_description     Root Disk
    check_command           check_nrpe!check_root_disk
}

define service {
    use                     generic-service
    host_name               gcp-client-1
    service_description     Current Load
    check_command           check_nrpe!check_load
}

define service {
    use                     generic-service
    host_name               gcp-client-1
    service_description     Total Processes
    check_command           check_nrpe!check_total_procs
}
```

Validate Nagios config:

```bash
sudo nagios4 -v /etc/nagios4/nagios.cfg
```

If no errors:

```bash
sudo systemctl restart nagios4
```

Ubuntu recommends validating config before restarting Nagios so broken object/service definitions do not break the monitoring service. ([Ubuntu Community Hub][1])

---

## 9. Verify from UI

Open:

```text
http://NAGIOS_SERVER_EXTERNAL_IP/nagios4
```

Go to:

```text
Hosts
Services
```

You should see:

```text
localhost
gcp-client-1
```

Services should show:

```text
PING
SSH
HTTP
Root Disk
Current Load
Total Processes
```

Initially they may show `PENDING`. Wait a few minutes or click:

```text
Service Detail → Re-schedule next check
```

---

## 10. Common issues and fixes

### Issue 1: Nagios UI not opening

Check Apache:

```bash
sudo systemctl status apache2
sudo apache2ctl configtest
```

Check firewall:

```bash
gcloud compute firewall-rules list | grep nagios
```

Make sure port `80` is allowed to `nagios-server`.

---

### Issue 2: Login not working

Recreate password:

```bash
sudo htdigest /etc/nagios4/htdigest.users "Nagios4" nagiosadmin
sudo systemctl reload apache2
```

Do **not** use `-c` again unless you want to recreate the file.

---

### Issue 3: `CHECK_NRPE: Error - Could not connect`

Check these:

On client:

```bash
sudo systemctl status nagios-nrpe-server
sudo ss -lntp | grep 5666
```

On Nagios server:

```bash
nc -vz 10.160.0.3 5666
```

Check GCP firewall:

```bash
gcloud compute firewall-rules describe allow-nrpe-from-nagios
```

Check `allowed_hosts` in client:

```bash
grep allowed_hosts /etc/nagios/nrpe.cfg
```

---

### Issue 4: `NRPE: Command 'check_root_disk' not defined`

On client:

```bash
grep check_root_disk /etc/nagios/nrpe.cfg
sudo systemctl restart nagios-nrpe-server
```

Make sure the command name in Nagios server matches exactly:

```text
check_nrpe!check_root_disk
```

---

## 11. Optional: Add CPU stress test

On client:

```bash
sudo apt install -y stress
stress --cpu 2 --timeout 120
```

Then check Nagios UI. `Current Load` should increase.

---

## 12. Optional: Add disk alert test

On client:

```bash
df -h /
```

Create a temporary large file carefully:

```bash
fallocate -l 1G /tmp/testfile
```

Check Nagios disk service. Remove after test:

```bash
rm /tmp/testfile
```

---

## 13. Cleanup lab

Delete VMs:

```bash
gcloud compute instances delete nagios-server gcp-client-1 \
  --zone=asia-south1-a
```

Delete firewall rules:

```bash
gcloud compute firewall-rules delete allow-nagios-http allow-nrpe-from-nagios
```

---

## Final lab flow for interview explanation

You can explain like this:

> I created two Ubuntu VMs on GCP: one as the Nagios Core server and one as the monitored Linux client. I opened port 80 only for the Nagios UI and port 5666 only from the Nagios server to the client using GCP firewall tags. On the server, I installed Nagios Core, Apache, plugins, and the NRPE plugin. On the client, I installed NRPE server and monitoring plugins, configured `allowed_hosts` with the Nagios server private IP, and defined custom checks for disk, load, and processes. Then I added the client host and service definitions in Nagios, validated the config using `nagios4 -v`, restarted Nagios, and verified host/service status from the Nagios UI.

[1]: https://discourse.ubuntu.com/t/nagios-core-4-installation-and-configuration/51519 "Nagios Core 4 Installation and Configuration - Tutorials - Ubuntu Community Hub"
[2]: https://docs.cloud.google.com/firewall/docs/using-firewalls "Use VPC firewall rules  |  Cloud Next Generation Firewall  |  Google Cloud Documentation"
[3]: https://exchange.nagios.org/directory/addons/monitoring-agents/nrpe-2d-nagios-remote-plugin-executor/details?utm_source=chatgpt.com "NRPE - Nagios Remote Plugin Executor"
[4]: https://www.nagios.org/downloads/nagios-plugins/ "The Official Nagios Plugins | Nagios Open Source"
