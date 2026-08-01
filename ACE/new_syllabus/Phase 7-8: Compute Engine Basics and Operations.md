# Phase 7: Compute Engine Basics

## 1. Compute Engine Overview

Google Compute Engine is an Infrastructure as a Service offering that lets you create and operate virtual machines on Google Cloud infrastructure.

A Compute Engine VM can be configured with:

- Operating system
- vCPUs and memory
- Boot and data disks
- Internal and external IP addresses
- Network interfaces
- Service account
- Firewall access
- Availability and maintenance policies
- Startup and shutdown scripts
- Labels, tags, and metadata

Compute Engine supports general-purpose, compute-optimized, memory-optimized, storage-optimized, accelerator-optimized, and other specialized machine families. citeturn216546search17turn216546search16

### Common use cases

- Hosting web applications
- Running legacy applications
- Application servers
- Jenkins or CI/CD servers
- Self-managed databases
- Batch-processing workloads
- Development and testing environments
- Kubernetes worker nodes
- GPU-based machine learning workloads
- Custom software requiring operating-system-level control

### Compute Engine versus serverless services

| Requirement | Better option |
|---|---|
| Full operating system control | Compute Engine |
| Custom kernel or system package | Compute Engine |
| Simple stateless container deployment | Cloud Run |
| Event-driven function | Cloud Run functions |
| Managed Kubernetes | GKE |
| Managed relational database | Cloud SQL or AlloyDB |

### Shared responsibility

Google manages:

- Physical servers
- Data-center facilities
- Networking infrastructure
- Hypervisor
- Hardware replacement

The customer manages:

- Guest operating system
- OS patches
- Installed packages
- Application configuration
- Firewall configuration
- IAM permissions
- Data and application security

VM Manager can reduce some OS-management work by providing patch management, OS policy management, and OS inventory management. citeturn365292search1turn365292search11

---

# 2. Machine Types

A machine type determines the virtual hardware assigned to a VM, primarily:

- Number of vCPUs
- Amount of memory
- Maximum network bandwidth
- Supported disk options
- Supported GPU or accelerator options

Google Cloud organizes machine types into:

1. Machine families
2. Machine series
3. Machine types

Example:

```text
General-purpose family
        ↓
E2 machine series
        ↓
e2-standard-2 machine type
```

## Common machine families

| Machine family | Main purpose | Example workloads |
|---|---|---|
| General-purpose | Balanced CPU and memory | Web servers, APIs, application servers |
| Compute-optimized | High CPU performance | Gaming servers, media encoding, scientific computing |
| Memory-optimized | Very high memory | SAP HANA, in-memory databases |
| Storage-optimized | High storage throughput | Analytics and storage-heavy workloads |
| Accelerator-optimized | GPU-heavy workloads | AI training, inference, rendering |

## Common general-purpose series

### E2

- Cost-effective
- Suitable for development, testing, and general workloads
- Common choice for ACE labs

Examples:

```text
e2-micro
e2-small
e2-medium
e2-standard-2
e2-standard-4
```

### N2 and N2D

- Higher and more consistent performance than basic E2 workloads
- Suitable for production applications
- N2 uses Intel processors
- N2D uses AMD processors

### C-series

- Compute-optimized
- Suitable for CPU-intensive workloads

### M-series

- Memory-optimized
- Suitable for large in-memory databases and enterprise workloads

## Machine type naming

Example:

```text
e2-standard-4
```

Meaning:

- `e2`: machine series
- `standard`: balanced memory-to-CPU ratio
- `4`: four vCPUs

Another example:

```text
e2-highmem-4
```

This provides four vCPUs with more memory than a standard machine type.

## Shared-core machine types

Examples include:

```text
e2-micro
e2-small
e2-medium
```

These machines share a physical CPU with other VMs and receive CPU time according to their configuration.

They are suitable for:

- Small websites
- Development environments
- Low-traffic applications
- Lightweight agents
- Practice labs

They are generally not suitable for applications requiring sustained CPU performance.

---

# 3. Custom Machine Types

A custom machine type lets you select a specific number of vCPUs and a specific amount of memory instead of using a predefined machine type.

For example, suppose predefined options are:

```text
e2-standard-4: 4 vCPUs and 16 GB memory
e2-standard-8: 8 vCPUs and 32 GB memory
```

But your application requires:

```text
6 vCPUs and 24 GB memory
```

You can create a custom machine type instead of overprovisioning an eight-vCPU VM.

## Benefits

- Better resource utilization
- Reduced overprovisioning
- Potential cost savings
- More accurate workload sizing

## When to use

Use custom machine types when:

- The application has unusual CPU-to-memory requirements
- A predefined machine is larger than necessary
- Monitoring data provides clear resource requirements
- You are optimizing a mature workload

Avoid custom machine types when:

- You do not yet understand the workload
- A predefined machine type is already suitable
- Operational simplicity is more important than minor cost savings

## CLI example

```bash
gcloud compute instances create custom-vm \
    --zone=asia-south1-a \
    --custom-cpu=4 \
    --custom-memory=10GB \
    --image-family=debian-12 \
    --image-project=debian-cloud
```

To use extended memory:

```bash
gcloud compute instances create custom-memory-vm \
    --zone=asia-south1-a \
    --custom-cpu=4 \
    --custom-memory=30GB \
    --custom-extensions \
    --image-family=debian-12 \
    --image-project=debian-cloud
```

Custom machine type limits depend on the selected machine series.

---

# 4. Boot Disk

A boot disk contains:

- Operating system
- Bootloader
- System files
- Installed applications
- VM configuration stored inside the operating system

Every VM requires a boot disk.

A boot disk can be created from:

- Public OS image
- Custom image
- Snapshot
- Existing disk

Google Cloud supports creating customized boot disks from public images, custom images, and boot-disk snapshots. citeturn365292search29

## Common public images

- Debian
- Ubuntu
- Red Hat Enterprise Linux
- Rocky Linux
- Windows Server
- Container-Optimized OS
- SQL Server images

## Boot disk deletion behavior

During VM creation, you can choose whether the boot disk should be deleted when the VM is deleted.

Typical setting:

```text
Delete boot disk when instance is deleted: Enabled
```

For important workloads, you might disable automatic deletion so that the disk remains after deleting the VM.

## Important exam point

A VM and its disk are separate resources.

Deleting a VM does not necessarily have to delete its boot or data disks. The behavior depends on the disk's auto-delete setting.

---

# 5. Persistent Disk

Persistent Disk is durable network-attached block storage for Compute Engine VMs.

Although it appears as a physical disk inside the VM, it is stored independently from the physical host running the VM. Data travels between the VM and the disk over Google's network. citeturn216546search3

## Characteristics

- Durable
- Network-attached
- Can remain after VM deletion
- Can be detached and attached to another compatible VM
- Can be resized
- Supports snapshots
- Automatically encrypted
- Performance can scale with disk size and VM resources

## Common Persistent Disk types

| Disk type | CLI name | Best for |
|---|---|---|
| Standard Persistent Disk | `pd-standard` | Sequential workloads, backups, low-cost storage |
| Balanced Persistent Disk | `pd-balanced` | General-purpose workloads |
| SSD Persistent Disk | `pd-ssd` | Databases and random I/O |
| Extreme Persistent Disk | `pd-extreme` | High-end database workloads |

Balanced Persistent Disk is commonly suitable for application servers, boot disks, and general workloads. SSD Persistent Disk is more suitable when an application requires higher random IOPS. citeturn216546search3turn216546search20

## Persistent Disk versus Local SSD

| Persistent Disk | Local SSD |
|---|---|
| Network-attached | Physically attached to host |
| Durable | Temporary/ephemeral |
| Supports snapshots | Cannot be directly snapshotted like Persistent Disk |
| Can be detached | Tied to VM lifecycle and host |
| Lower latency than object storage | Very high IOPS and low latency |
| Suitable for durable application data | Suitable for caches and temporary processing |

---

# 6. Zonal Persistent Disk

A zonal Persistent Disk exists within one Google Cloud zone.

Example:

```text
Region: asia-south1
Zone: asia-south1-a
Disk: web-data-disk
```

The disk can normally be attached to a VM in the same zone.

## Suitable workloads

- Development environments
- Single-zone web servers
- Application servers
- Non-critical databases
- Workloads protected through snapshots or application-level replication

## Advantages

- Lower cost than regional replication
- Simple to manage
- Good performance
- Suitable for most ordinary VM workloads

## Limitation

If the entire zone becomes unavailable, the disk cannot immediately be attached to a VM in another zone as if it were a regional disk.

Snapshots can still be used to create another disk, but this is a recovery workflow rather than synchronous zonal failover.

---

# 7. Regional Persistent Disk

A regional Persistent Disk synchronously replicates data between two zones in the same region.

For example:

```text
Region: asia-south1

Replica 1: asia-south1-a
Replica 2: asia-south1-b
```

Regional Persistent Disk provides greater resilience against a zonal failure than a zonal Persistent Disk. Google recommends combining regional disks with other high-availability practices, including snapshots and regional managed instance groups. citeturn216546search3turn216546search31

## Suitable workloads

- High-availability databases
- Stateful applications
- Workloads requiring lower RPO
- Applications that must recover from a zonal failure
- Regional managed instance groups with stateful disks

## Zonal versus regional Persistent Disk

| Feature | Zonal disk | Regional disk |
|---|---|---|
| Replication scope | One zone | Two zones |
| Zonal-failure resilience | Lower | Higher |
| Cost | Lower | Higher |
| Write latency | Generally lower | May be higher because of replication |
| Typical use | General workloads | Critical stateful workloads |

## Important limitation

Regional Persistent Disk does not automatically provide full application failover.

You still need:

- Another VM in the second zone
- Application failover logic
- Health checking
- Database recovery or clustering
- DNS or load-balancing changes

The disk protects the storage layer, not the entire application architecture.

---

# 8. Hyperdisk

Hyperdisk is Google Cloud's newer generation of durable network block storage.

It allows storage performance to be provisioned more independently from storage capacity. For supported Hyperdisk types, you can configure values such as:

- Disk size
- IOPS
- Throughput

Google describes Hyperdisk as its recommended durable block-storage option, although availability depends on machine series and region. citeturn216546search24turn216546search8

## Common Hyperdisk types

### Hyperdisk Balanced

Suitable for:

- General-purpose production workloads
- Application servers
- Databases
- Boot and data disks
- Workloads requiring adjustable IOPS and throughput

### Hyperdisk Throughput

Suitable for:

- Large sequential reads and writes
- Data analytics
- Hadoop-style workloads
- Log processing
- Large data pipelines

### Hyperdisk Extreme

Suitable for:

- High-performance databases
- Very high IOPS requirements
- Latency-sensitive enterprise applications

### Hyperdisk ML

Suitable for:

- Machine learning model loading
- Read-heavy workloads
- Sharing model data with multiple accelerator-based VMs

## Persistent Disk versus Hyperdisk

| Persistent Disk | Hyperdisk |
|---|---|
| Traditional Google Cloud block storage | Newer block-storage generation |
| Performance often related to disk size and VM limits | Performance can be provisioned separately |
| Broad machine-family compatibility | Requires supported machine series |
| Suitable for standard workloads | Suitable for advanced and performance-sensitive workloads |
| Often easier for ACE labs | More likely in architecture and product-selection questions |

## Exam decision

Choose Hyperdisk when:

- The question requires independently configurable IOPS or throughput
- A high-performance database needs predictable storage performance
- The selected machine series supports Hyperdisk
- A modern scalable block-storage solution is required

Choose Persistent Disk when:

- The machine type does not support Hyperdisk
- The workload is ordinary
- Simplicity and broad compatibility are priorities

---

# 9. Launching a VM

Before creating a VM, decide:

- Project
- Region and zone
- Machine family and type
- Operating system
- Boot-disk type and size
- Network and subnet
- Internal and external IP requirements
- Firewall requirements
- Service account
- Access scopes
- Availability policy
- Labels and network tags

## GUI steps

1. Open Google Cloud Console.
2. Go to **Compute Engine → VM instances**.
3. Click **Create instance**.
4. Enter:

```text
Name: ace-web-vm
Region: asia-south1
Zone: asia-south1-a
```

5. Under **Machine configuration**, select:

```text
Series: E2
Machine type: e2-micro
```

6. Under **OS and storage**, click **Change**.
7. Select:

```text
Operating system: Debian
Version: Debian 12
Boot disk type: Balanced Persistent Disk
Size: 10 GB
```

8. Under **Networking**, select the required VPC and subnet.
9. Under **Firewall**, select:

```text
Allow HTTP traffic
```

10. Click **Create**.

## CLI preparation

```bash
gcloud auth login
gcloud config set project PROJECT_ID
gcloud config set compute/region asia-south1
gcloud config set compute/zone asia-south1-a
```

Enable Compute Engine API:

```bash
gcloud services enable compute.googleapis.com
```

Create the VM:

```bash
gcloud compute instances create ace-web-vm \
    --zone=asia-south1-a \
    --machine-type=e2-micro \
    --image-family=debian-12 \
    --image-project=debian-cloud \
    --boot-disk-type=pd-balanced \
    --boot-disk-size=10GB \
    --tags=http-server
```

Create an HTTP firewall rule if one does not already exist:

```bash
gcloud compute firewall-rules create allow-http \
    --network=default \
    --direction=INGRESS \
    --action=ALLOW \
    --rules=tcp:80 \
    --source-ranges=0.0.0.0/0 \
    --target-tags=http-server
```

---

# 10. SSH to a VM

SSH provides command-line access to a Linux VM.

You can connect using:

- SSH button in Google Cloud Console
- `gcloud compute ssh`
- OpenSSH client
- Identity-Aware Proxy
- Third-party SSH tools

When you connect through the Google Cloud Console or Google Cloud CLI, Compute Engine can create and manage SSH keys on your behalf. citeturn365292search32

## Console method

1. Open **Compute Engine → VM instances**.
2. Locate the VM.
3. Click **SSH**.
4. A browser-based terminal opens.

## CLI method

```bash
gcloud compute ssh ace-web-vm \
    --zone=asia-south1-a
```

Run a remote command without opening an interactive terminal:

```bash
gcloud compute ssh ace-web-vm \
    --zone=asia-south1-a \
    --command="hostname && uptime"
```

## SSH without an external IP

For a VM without an external IP, common access options include:

- IAP TCP forwarding
- Bastion host
- VPN
- Cloud Interconnect
- Connecting from another VM on the VPC

Example using IAP:

```bash
gcloud compute ssh private-vm \
    --zone=asia-south1-a \
    --tunnel-through-iap
```

The firewall must allow IAP's TCP forwarding source range to port 22.

---

# 11. OS Login

OS Login uses IAM to control SSH access to Linux VMs.

Instead of maintaining SSH keys in project or instance metadata, OS Login associates the Linux account with the user's Google identity and IAM permissions. citeturn365292search0turn365292search32

## Benefits

- Centralized SSH access management
- IAM-based authorization
- Easier access revocation
- Better auditability
- Consistent Linux identities
- Supports two-factor authentication
- Reduces unmanaged metadata-based SSH keys

## Important roles

### `roles/compute.osLogin`

Allows a user to log in without administrative sudo access.

### `roles/compute.osAdminLogin`

Allows a user to log in and use administrative privileges.

### `roles/iam.serviceAccountUser`

May be required when the VM uses a service account and the user needs permission to act as that service account during access.

## Enable OS Login at project level

```bash
gcloud compute project-info add-metadata \
    --metadata=enable-oslogin=TRUE
```

Enable OS Login on a specific VM:

```bash
gcloud compute instances add-metadata ace-web-vm \
    --zone=asia-south1-a \
    --metadata=enable-oslogin=TRUE
```

Grant basic OS Login access:

```bash
gcloud projects add-iam-policy-binding PROJECT_ID \
    --member="user:user@example.com" \
    --role="roles/compute.osLogin"
```

Grant administrative OS Login:

```bash
gcloud projects add-iam-policy-binding PROJECT_ID \
    --member="user:user@example.com" \
    --role="roles/compute.osAdminLogin"
```

## OS Login exam point

For centralized SSH access across many VMs, use:

```text
OS Login + IAM
```

Do not manually distribute SSH keys to every VM unless there is a specific requirement.

---

# 12. Availability Policy

The availability policy controls how a VM behaves during host maintenance and infrastructure failures.

The two major settings are:

1. On-host maintenance behavior
2. Automatic restart

## On-host maintenance

### Migrate

Compute Engine live-migrates the VM to another host during planned maintenance when supported.

Benefits:

- Minimal interruption
- Suitable for long-running services
- Default behavior for many standard VM configurations

### Terminate

The VM is stopped during host maintenance.

Use this when:

- The VM does not support live migration
- The workload can tolerate interruption
- The VM uses certain accelerator configurations
- The application handles restart independently

For standard instances, the default maintenance behavior is generally migration when the machine configuration supports it. citeturn365292search8turn365292search17

## Automatic restart

When automatic restart is enabled, Google attempts to restart the VM after infrastructure-related termination or host failure.

Automatic restart does not restart a VM that the user intentionally stopped.

## CLI example

```bash
gcloud compute instances set-scheduling ace-web-vm \
    --zone=asia-south1-a \
    --maintenance-policy=MIGRATE \
    --restart-on-failure
```

Set termination on maintenance:

```bash
gcloud compute instances set-scheduling ace-web-vm \
    --zone=asia-south1-a \
    --maintenance-policy=TERMINATE \
    --no-restart-on-failure
```

Google documents `gcloud compute instances set-scheduling` as the command for changing VM host-maintenance and automatic-restart settings. citeturn365292search16

---

# 13. Spot VM

A Spot VM uses spare Google Cloud capacity at a lower price.

Google Cloud can stop or preempt the VM when it needs the resources for other workloads.

## Characteristics

- Lower cost than standard VMs
- No guarantee of continuous availability
- Can be preempted
- Suitable for interruption-tolerant workloads
- Not suitable for critical single-instance applications
- Should save progress externally

## Suitable workloads

- Batch processing
- CI/CD workers
- Video rendering
- Data processing
- Stateless web workers
- Fault-tolerant distributed workloads
- Machine learning experiments
- Development and testing

## Unsuitable workloads

- Single production database
- Stateful application without replication
- Critical long-running transaction
- Application that cannot resume after interruption

## Spot VM best practices

- Use managed instance groups
- Store data on Persistent Disk, Cloud Storage, or a database
- Use shutdown scripts
- Use checkpointing
- Design jobs to retry
- Keep application instances stateless

Managed instance groups can recreate Spot VMs when capacity becomes available. citeturn216546search26

## CLI example

```bash
gcloud compute instances create spot-worker \
    --zone=asia-south1-a \
    --machine-type=e2-standard-2 \
    --provisioning-model=SPOT \
    --instance-termination-action=STOP \
    --image-family=debian-12 \
    --image-project=debian-cloud
```

To have the VM deleted after preemption:

```bash
--instance-termination-action=DELETE
```

---

# 14. View Running VM Instances

## Console

Go to:

```text
Compute Engine → VM instances
```

You can view:

- VM name
- Zone
- Machine type
- Internal IP
- External IP
- Status
- Network
- CPU usage
- Recommendation information

## CLI

List all VMs:

```bash
gcloud compute instances list
```

List only running VMs:

```bash
gcloud compute instances list \
    --filter="status=RUNNING"
```

List VMs in a specific zone:

```bash
gcloud compute instances list \
    --filter="zone:(asia-south1-a)"
```

Display selected columns:

```bash
gcloud compute instances list \
    --format="table(
        name,
        zone.basename(),
        machineType.basename(),
        status,
        networkInterfaces[0].networkIP,
        networkInterfaces[0].accessConfigs[0].natIP
    )"
```

Describe one VM:

```bash
gcloud compute instances describe ace-web-vm \
    --zone=asia-south1-a
```

Get only the external IP:

```bash
gcloud compute instances describe ace-web-vm \
    --zone=asia-south1-a \
    --format="get(networkInterfaces[0].accessConfigs[0].natIP)"
```

---

# Mini Lab 1: Create VM, SSH, Install Nginx, and Access It

## Objective

Create a Linux VM, connect through SSH, install Nginx, and access the web page through the browser.

## Architecture

```text
Internet
   |
Firewall rule: TCP 80
   |
External IP
   |
Compute Engine VM
   |
Nginx
```

## GUI lab

### Step 1: Create the VM

1. Open **Compute Engine → VM instances**.
2. Click **Create instance**.
3. Configure:

```text
Name: nginx-vm
Region: asia-south1
Zone: asia-south1-a
Machine type: e2-micro
Operating system: Debian 12
Boot disk: 10 GB Balanced Persistent Disk
```

4. Select **Allow HTTP traffic**.
5. Click **Create**.

### Step 2: SSH to the VM

1. Wait until the VM status becomes **Running**.
2. Click **SSH**.

### Step 3: Install Nginx

```bash
sudo apt-get update
sudo apt-get install -y nginx
```

Check the service:

```bash
sudo systemctl status nginx --no-pager
```

Enable it at boot:

```bash
sudo systemctl enable nginx
```

### Step 4: Create a custom page

```bash
sudo tee /var/www/html/index.html > /dev/null <<'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>GCP ACE Lab</title>
</head>
<body>
    <h1>Hello from Google Compute Engine</h1>
    <p>Nginx is running successfully.</p>
</body>
</html>
EOF
```

### Step 5: Test inside the VM

```bash
curl http://localhost
```

### Step 6: Test from browser

Copy the VM's external IP and open:

```text
http://EXTERNAL_IP
```

## Complete CLI lab

Set variables:

```bash
export PROJECT_ID="$(gcloud config get-value project)"
export REGION="asia-south1"
export ZONE="asia-south1-a"
export VM_NAME="nginx-vm"
```

Set default region and zone:

```bash
gcloud config set compute/region "$REGION"
gcloud config set compute/zone "$ZONE"
```

Create firewall rule:

```bash
gcloud compute firewall-rules describe allow-http \
    --format="value(name)" 2>/dev/null || \
gcloud compute firewall-rules create allow-http \
    --network=default \
    --direction=INGRESS \
    --priority=1000 \
    --action=ALLOW \
    --rules=tcp:80 \
    --source-ranges=0.0.0.0/0 \
    --target-tags=http-server
```

Create the VM with a startup script:

```bash
gcloud compute instances create "$VM_NAME" \
    --zone="$ZONE" \
    --machine-type=e2-micro \
    --image-family=debian-12 \
    --image-project=debian-cloud \
    --boot-disk-type=pd-balanced \
    --boot-disk-size=10GB \
    --tags=http-server \
    --metadata=startup-script='#!/bin/bash
apt-get update
apt-get install -y nginx
cat > /var/www/html/index.html <<EOF
<!DOCTYPE html>
<html>
<head><title>GCP ACE Lab</title></head>
<body>
<h1>Hello from Google Compute Engine</h1>
<p>Installed through a startup script.</p>
</body>
</html>
EOF
systemctl enable nginx
systemctl restart nginx'
```

View the VM:

```bash
gcloud compute instances list \
    --filter="name=$VM_NAME"
```

Get its external IP:

```bash
export EXTERNAL_IP="$(gcloud compute instances describe "$VM_NAME" \
    --zone="$ZONE" \
    --format='get(networkInterfaces[0].accessConfigs[0].natIP)')"

echo "Open: http://$EXTERNAL_IP"
```

Test with curl:

```bash
curl "http://$EXTERNAL_IP"
```

SSH to the VM:

```bash
gcloud compute ssh "$VM_NAME" \
    --zone="$ZONE"
```

## Cleanup

```bash
gcloud compute instances delete "$VM_NAME" \
    --zone="$ZONE" \
    --quiet
```

---

# Phase 8: Compute Engine Operations

# 15. VM Snapshots

A disk snapshot is a point-in-time backup of a Persistent Disk or supported Hyperdisk volume.

Snapshots are commonly used to:

- Back up data disks
- Protect boot disks
- Restore an accidentally deleted file system
- Create a new disk
- Move data to another zone or region
- Support disaster recovery

Google recommends snapshot schedules as a straightforward way to create recurring backups. citeturn365292search20turn365292search45

## Snapshot characteristics

- Incremental
- Stored independently from the source disk
- Can be used to create new disks
- Can restore to another supported location
- Can be created while the source VM is running
- Application consistency might require application quiescing or guest-aware processes

## Snapshot versus image

| Snapshot | Custom image |
|---|---|
| Primarily a disk backup | Primarily a reusable VM boot template |
| Common for data recovery | Common for standardized VM creation |
| Can capture boot or data disks | Usually created from a configured boot disk |
| Used to create a disk | Used directly as an image source for VMs |
| Good for periodic backup | Good for golden-image deployment |

## Snapshot versus machine image

| Snapshot | Machine image |
|---|---|
| Captures one disk | Captures VM configuration and attached disks |
| Storage-focused backup | VM-level backup |
| Does not capture complete VM settings | Captures more complete instance configuration |
| Useful for disk restore | Useful for VM cloning and recovery |

---

# 16. Create a Snapshot

## GUI steps

1. Go to **Compute Engine → Snapshots**.
2. Click **Create snapshot**.
3. Enter:

```text
Name: nginx-boot-snapshot
Source disk: nginx-vm
Snapshot type: Standard
Location: Default or selected region
```

4. Click **Create**.

## CLI

First identify the disk:

```bash
gcloud compute disks list
```

Create the snapshot:

```bash
gcloud compute snapshots create nginx-boot-snapshot \
    --source-disk=nginx-vm \
    --source-disk-zone=asia-south1-a \
    --snapshot-type=STANDARD
```

Google recommends `gcloud compute snapshots create` for standard snapshot creation because it supports more features than the older disk-specific snapshot command. citeturn365292search35

List snapshots:

```bash
gcloud compute snapshots list
```

Describe a snapshot:

```bash
gcloud compute snapshots describe nginx-boot-snapshot
```

Create a new disk from the snapshot:

```bash
gcloud compute disks create restored-nginx-disk \
    --zone=asia-south1-a \
    --source-snapshot=nginx-boot-snapshot \
    --type=pd-balanced
```

---

# 17. Schedule Snapshots

A snapshot schedule automatically creates snapshots at a defined interval.

Snapshot schedules can be applied to supported:

- Zonal Persistent Disk
- Regional Persistent Disk
- Hyperdisk volumes

Google Cloud implements snapshot schedules through resource policies. citeturn365292search6turn365292search10

## Why schedule snapshots?

Manual snapshots are unreliable because someone may forget to create them.

A snapshot schedule provides:

- Regular backups
- Retention configuration
- Automated deletion of old snapshots
- Consistent recovery points
- Lower operational effort

## GUI steps

1. Go to **Compute Engine → Snapshots**.
2. Open **Snapshot schedules**.
3. Click **Create snapshot schedule**.
4. Configure:

```text
Name: daily-snapshot-policy
Region: asia-south1
Frequency: Daily
Start time: 02:00
Retention: 7 days
Deletion rule: Keep snapshots when source disk is deleted
```

5. Create the schedule.
6. Open **Compute Engine → Disks**.
7. Select the disk.
8. Click **Edit**.
9. Attach `daily-snapshot-policy`.

## CLI: create a daily schedule

```bash
gcloud compute resource-policies create snapshot-schedule daily-snapshot-policy \
    --region=asia-south1 \
    --max-retention-days=7 \
    --on-source-disk-delete=keep-auto-snapshots \
    --daily-schedule \
    --start-time=02:00
```

Attach it to a zonal disk:

```bash
gcloud compute disks add-resource-policies nginx-vm \
    --zone=asia-south1-a \
    --resource-policies=daily-snapshot-policy
```

View the policy:

```bash
gcloud compute resource-policies describe daily-snapshot-policy \
    --region=asia-south1
```

Remove the policy from the disk:

```bash
gcloud compute disks remove-resource-policies nginx-vm \
    --zone=asia-south1-a \
    --resource-policies=daily-snapshot-policy
```

---

# 18. Create a Custom Image

A custom image is a reusable boot-disk image created from:

- Existing disk
- Snapshot
- Another image
- Imported virtual-disk file

A custom image is commonly used as a golden image.

## Golden-image example

An organization creates a VM and installs:

- Security agents
- Monitoring agent
- Java runtime
- Web server
- Trusted certificates
- Standard configuration

It then creates a custom image:

```text
company-webserver-v1
```

All future VMs use this approved image.

## Benefits

- Faster VM provisioning
- Standardized configuration
- Consistent security controls
- Reduced startup-script complexity
- Easier versioning
- Suitable for instance templates and MIGs

## Best practice before creating an image

- Remove temporary files
- Remove application secrets
- Avoid embedding credentials
- Stop applications cleanly
- Validate startup behavior
- Generalize the operating system when necessary
- Prefer immutable version names

Examples:

```text
webserver-v1
webserver-v2
webserver-2026-08-01
```

## GUI steps

1. Go to **Compute Engine → Images**.
2. Click **Create image**.
3. Enter:

```text
Name: nginx-golden-image-v1
Source: Disk
Source disk: nginx-vm
Location: Multi-region or selected region
```

4. Click **Create**.

## CLI from an existing disk

For the cleanest result, stop the source VM first:

```bash
gcloud compute instances stop nginx-vm \
    --zone=asia-south1-a
```

Create the image:

```bash
gcloud compute images create nginx-golden-image-v1 \
    --source-disk=nginx-vm \
    --source-disk-zone=asia-south1-a
```

Restart the VM:

```bash
gcloud compute instances start nginx-vm \
    --zone=asia-south1-a
```

List images:

```bash
gcloud compute images list \
    --no-standard-images
```

Create a VM from the custom image:

```bash
gcloud compute instances create nginx-from-image \
    --zone=asia-south1-a \
    --machine-type=e2-micro \
    --image=nginx-golden-image-v1 \
    --image-project="$(gcloud config get-value project)" \
    --tags=http-server
```

---

# 19. Delete an Image or Snapshot

## Delete a snapshot

```bash
gcloud compute snapshots delete nginx-boot-snapshot \
    --quiet
```

## Delete an image

```bash
gcloud compute images delete nginx-golden-image-v1 \
    --quiet
```

## Important exam point

Deleting a snapshot does not normally delete disks that were previously created from it.

Similarly, deleting a custom image does not delete VMs that were already created from that image.

Once the new disk or VM has been created, it is an independent resource.

---

# 20. VM Manager

VM Manager is a collection of tools for managing Linux and Windows operating systems across Compute Engine VM fleets.

Its main capabilities include:

- Patch management
- OS inventory management
- OS policies
- Configuration compliance
- Software and package visibility

citeturn365292search1turn365292search44

## Patch management

Used to:

- Deploy operating-system patches
- Schedule patch jobs
- Patch selected groups of VMs
- Review patch status
- Control reboot behavior
- Patch Windows and Linux fleets

Example:

```text
Patch all production Linux VMs every Sunday at 02:00.
```

## OS inventory management

Collects information such as:

- Operating-system version
- Installed packages
- Available package updates
- Vulnerability-related information
- VM inventory data

Example:

```text
Find all VMs running an outdated version of OpenSSL.
```

## OS policies

Used to define desired operating-system configurations.

Examples:

- Ensure a package is installed
- Ensure a package is absent
- Deploy configuration files
- Run validation scripts
- Enforce configuration standards

## Enable VM Manager

Enable the OS Config API:

```bash
gcloud services enable osconfig.googleapis.com
```

Enable VM Manager features for the project:

```bash
gcloud compute os-config project-feature-settings update \
    --patch-and-config-feature-set=full
```

Google documents this project-feature-settings command as part of enabling the complete VM Manager feature set. citeturn365292search15

## ACE exam point

Use VM Manager when the question asks to:

- Patch many VMs centrally
- Check installed OS packages
- Maintain OS configuration compliance
- Manage Linux or Windows operating systems at fleet scale

VM Manager is not used to:

- Autoscale VMs
- Load-balance traffic
- Create Kubernetes clusters
- Replace Cloud Monitoring
- Back up application data

---

# 21. Managed Instance Group Basics

An instance group is a collection of VM instances.

Google Cloud supports:

1. Managed instance groups
2. Unmanaged instance groups

## Managed instance group

A Managed Instance Group, or MIG, manages a group of VMs as one logical resource.

MIG instances are created from an instance template.

MIG capabilities include:

- Autoscaling
- Autohealing
- Regional multi-zone deployment
- Rolling updates
- Automatic recreation of failed VMs
- Integration with load balancers

citeturn216546search1turn216546search13

## Unmanaged instance group

An unmanaged instance group contains VMs that you manage individually.

It does not automatically provide the complete lifecycle-management capabilities of a MIG.

## MIG use cases

- Horizontally scaled web applications
- Stateless API servers
- Application backends
- Worker pools
- Batch workers
- Load-balancer backends
- Highly available services

## Stateless versus stateful MIGs

### Stateless MIG

Instances are considered replaceable.

Store application data outside the VM in:

- Cloud SQL
- Spanner
- Firestore
- Cloud Storage
- Memorystore
- External database

### Stateful MIG

Preserves selected state, such as:

- Persistent disks
- Instance names
- Metadata
- IP addresses

Stateful MIGs can be used for databases, legacy applications, and checkpoint-based processing, although they require more careful design. citeturn216546search30turn216546search21

---

# 22. Instance Template

An instance template stores a reusable VM configuration.

It can include:

- Machine type
- Boot-disk image
- Disk settings
- Network
- Subnet
- Service account
- Network tags
- Labels
- Metadata
- Startup script
- Availability policies

Instance templates can be used to create individual VMs, managed instance groups, and reservations. citeturn216546search18

## Important characteristic

An instance template is effectively immutable.

Instead of editing an existing template, normally:

1. Create a new template
2. Update the MIG to use it
3. Perform a rolling replacement or rolling update

Example:

```text
web-template-v1
web-template-v2
web-template-v3
```

## GUI steps

1. Go to **Compute Engine → Instance templates**.
2. Click **Create instance template**.
3. Configure:

```text
Name: web-template-v1
Machine type: e2-micro
Boot image: Debian 12
Network tag: http-server
```

4. Add a startup script:

```bash
#!/bin/bash
apt-get update
apt-get install -y nginx
echo "<h1>Served by $(hostname)</h1>" > /var/www/html/index.html
systemctl restart nginx
```

5. Click **Create**.

## CLI

Create a startup-script file:

```bash
cat > startup.sh <<'EOF'
#!/bin/bash
apt-get update
apt-get install -y nginx
cat > /var/www/html/index.html <<HTML
<!DOCTYPE html>
<html>
<body>
<h1>Google Cloud Managed Instance Group</h1>
<p>Served by $(hostname)</p>
</body>
</html>
HTML
systemctl enable nginx
systemctl restart nginx
EOF
```

Create the template:

```bash
gcloud compute instance-templates create web-template-v1 \
    --machine-type=e2-micro \
    --image-family=debian-12 \
    --image-project=debian-cloud \
    --boot-disk-type=pd-balanced \
    --boot-disk-size=10GB \
    --network=default \
    --tags=http-server \
    --metadata-from-file=startup-script=startup.sh
```

List templates:

```bash
gcloud compute instance-templates list
```

Describe the template:

```bash
gcloud compute instance-templates describe web-template-v1
```

---

# 23. Autoscaled Managed Instance Group

Autoscaling automatically increases or decreases the number of VMs in a MIG.

The autoscaler can use signals such as:

- Average CPU utilization
- HTTP load-balancing utilization
- Cloud Monitoring metric
- Schedule
- Multiple combined signals

MIG autoscaling helps applications handle traffic increases while reducing costs during periods of lower demand. citeturn216546search4turn216546search22

## Example

Configuration:

```text
Minimum instances: 2
Maximum instances: 10
Target CPU utilization: 60%
```

Behavior:

- Average CPU rises above the target
- Autoscaler creates additional VMs
- Traffic decreases
- Autoscaler removes unnecessary VMs
- Group never goes below two or above ten instances

## Important concepts

### Minimum replicas

The smallest number of VMs the group keeps.

### Maximum replicas

The largest number of VMs the group can create.

### Target utilization

The desired average load, such as:

```text
60% CPU
```

### Initialization period

The approximate time an application requires to start and become ready.

The autoscaler should not make aggressive decisions based on a VM that is still initializing.

### Cooldown or stabilization behavior

Autoscaling avoids immediately adding and removing instances for short-lived traffic changes.

## Zonal MIG

All VMs are created in one zone.

Advantages:

- Simpler
- Suitable for labs
- Lower architectural complexity

Limitation:

- A zonal outage can affect the complete group

## Regional MIG

VMs are distributed across multiple zones in a region.

Regional MIGs improve resilience against zonal failures. If one zone fails, instances in other zones can continue serving the application. citeturn216546search32turn216546search10

For production high availability, prefer a regional MIG when supported by the architecture.

---

# 24. Health Checks Basics

A health check periodically tests whether an application or VM is responding correctly.

Health checks can use protocols including:

- HTTP
- HTTPS
- HTTP/2
- TCP
- SSL
- gRPC

## Common health-check settings

| Setting | Meaning |
|---|---|
| Check interval | Time between probes |
| Timeout | How long to wait for a response |
| Healthy threshold | Successful checks required to mark healthy |
| Unhealthy threshold | Failed checks required to mark unhealthy |
| Port | Application port |
| Request path | HTTP endpoint such as `/health` |

## Health checks in MIGs

Health checks can support autohealing.

Example:

```text
GET http://VM_IP/health
```

If a VM repeatedly fails, the MIG can recreate or repair the unhealthy instance. citeturn216546search9turn216546search28

## Autohealing versus autoscaling

| Autohealing | Autoscaling |
|---|---|
| Replaces unhealthy VMs | Changes number of VMs |
| Focuses on application health | Focuses on capacity and load |
| Uses health check | Uses CPU, load-balancing, metrics, or schedules |
| Maintains quality of instances | Maintains required quantity |

## Load-balancer health check versus autohealing health check

A load balancer uses a health check to decide whether traffic should be sent to an instance.

A MIG autohealing policy uses a health check to decide whether an unhealthy VM should be repaired or recreated.

Google recommends being more conservative with autohealing health checks because an overly aggressive configuration can repeatedly recreate VMs during temporary application startup or dependency issues.

---

# Mini Lab 2: Create Instance Template, MIG, Health Check, and Autoscaling

## Objective

Build an automatically managed group of Nginx web servers.

## Architecture

```text
Instance template
       |
       v
Managed Instance Group
   |       |       |
 VM-1    VM-2    VM-N
       |
Autoscaler based on CPU
       |
Health check and autohealing
```

---

## Part A: GUI lab

### Step 1: Create the instance template

1. Go to **Compute Engine → Instance templates**.
2. Click **Create instance template**.
3. Configure:

```text
Name: ace-web-template-v1
Machine type: e2-micro
Boot disk: Debian 12
Network: default
Network tag: http-server
```

4. Open **Advanced options → Management → Automation**.
5. Add the startup script:

```bash
#!/bin/bash
apt-get update
apt-get install -y nginx
cat > /var/www/html/index.html <<EOF
<!DOCTYPE html>
<html>
<body>
<h1>ACE Managed Instance Group</h1>
<p>Hostname: $(hostname)</p>
</body>
</html>
EOF
systemctl enable nginx
systemctl restart nginx
```

6. Click **Create**.

### Step 2: Create the MIG

1. Go to **Compute Engine → Instance groups**.
2. Click **Create instance group**.
3. Choose **New managed instance group**.
4. Configure:

```text
Name: ace-web-mig
Location: Single zone
Region: asia-south1
Zone: asia-south1-a
Instance template: ace-web-template-v1
Number of instances: 2
```

5. Click **Create**.

### Step 3: Configure named port

Edit the MIG and configure:

```text
Port name: http
Port number: 80
```

Named ports help load-balancing components identify the application's serving port.

### Step 4: Configure autoscaling

Edit the group and enable autoscaling:

```text
Autoscaling signal: CPU utilization
Target CPU utilization: 60%
Minimum instances: 2
Maximum instances: 5
Initialization period: 60 seconds
```

### Step 5: Create health check

1. Go to **Compute Engine → Health checks**.
2. Click **Create health check**.
3. Configure:

```text
Name: nginx-health-check
Protocol: HTTP
Port: 80
Request path: /
Check interval: 10 seconds
Timeout: 5 seconds
Healthy threshold: 2
Unhealthy threshold: 3
```

4. Create the health check.

### Step 6: Attach autohealing policy

1. Open the MIG.
2. Click **Edit**.
3. Under **Autohealing**, select:

```text
Health check: nginx-health-check
Initial delay: 60 seconds
```

4. Save.

### Step 7: Verify instances

Open the MIG and select the **Instances** tab.

You should see two VMs created from the same template.

---

## Part B: Complete CLI lab

Set variables:

```bash
export PROJECT_ID="$(gcloud config get-value project)"
export REGION="asia-south1"
export ZONE="asia-south1-a"
export TEMPLATE_NAME="ace-web-template-v1"
export MIG_NAME="ace-web-mig"
export HEALTH_CHECK_NAME="nginx-health-check"
```

Enable the Compute Engine API:

```bash
gcloud services enable compute.googleapis.com
```

Create the HTTP firewall rule:

```bash
gcloud compute firewall-rules describe allow-http \
    --format="value(name)" 2>/dev/null || \
gcloud compute firewall-rules create allow-http \
    --network=default \
    --direction=INGRESS \
    --priority=1000 \
    --action=ALLOW \
    --rules=tcp:80 \
    --source-ranges=0.0.0.0/0 \
    --target-tags=http-server
```

Create the startup script:

```bash
cat > mig-startup.sh <<'EOF'
#!/bin/bash
apt-get update
apt-get install -y nginx stress-ng

cat > /var/www/html/index.html <<HTML
<!DOCTYPE html>
<html>
<head><title>ACE MIG Lab</title></head>
<body>
<h1>Google Cloud Managed Instance Group</h1>
<p>Served by: $(hostname)</p>
</body>
</html>
HTML

systemctl enable nginx
systemctl restart nginx
EOF
```

Create the instance template:

```bash
gcloud compute instance-templates create "$TEMPLATE_NAME" \
    --machine-type=e2-micro \
    --image-family=debian-12 \
    --image-project=debian-cloud \
    --boot-disk-type=pd-balanced \
    --boot-disk-size=10GB \
    --network=default \
    --tags=http-server \
    --metadata-from-file=startup-script=mig-startup.sh
```

Create the zonal MIG:

```bash
gcloud compute instance-groups managed create "$MIG_NAME" \
    --zone="$ZONE" \
    --template="$TEMPLATE_NAME" \
    --size=2 \
    --base-instance-name=ace-web
```

Configure the named port:

```bash
gcloud compute instance-groups managed set-named-ports "$MIG_NAME" \
    --zone="$ZONE" \
    --named-ports=http:80
```

Create an HTTP health check:

```bash
gcloud compute health-checks create http "$HEALTH_CHECK_NAME" \
    --port=80 \
    --request-path=/ \
    --check-interval=10s \
    --timeout=5s \
    --healthy-threshold=2 \
    --unhealthy-threshold=3
```

Configure autohealing:

```bash
gcloud compute instance-groups managed update "$MIG_NAME" \
    --zone="$ZONE" \
    --health-check="$HEALTH_CHECK_NAME" \
    --initial-delay=60
```

Configure CPU autoscaling:

```bash
gcloud compute instance-groups managed set-autoscaling "$MIG_NAME" \
    --zone="$ZONE" \
    --min-num-replicas=2 \
    --max-num-replicas=5 \
    --target-cpu-utilization=0.60 \
    --cool-down-period=60
```

View the MIG:

```bash
gcloud compute instance-groups managed describe "$MIG_NAME" \
    --zone="$ZONE"
```

List managed instances:

```bash
gcloud compute instance-groups managed list-instances "$MIG_NAME" \
    --zone="$ZONE"
```

Check autoscaler configuration:

```bash
gcloud compute instance-groups managed describe "$MIG_NAME" \
    --zone="$ZONE" \
    --format="yaml(autoscaler,autoHealingPolicies,targetSize)"
```

List health checks:

```bash
gcloud compute health-checks list
```

---

# 25. Test Autoscaling

Autoscaling is based on average utilization across the group, so generating load on only one VM might not always be enough to trigger scaling.

## Get instance names

```bash
gcloud compute instance-groups managed list-instances "$MIG_NAME" \
    --zone="$ZONE" \
    --format="value(instance.basename())"
```

## SSH to one instance

```bash
INSTANCE_NAME="$(gcloud compute instance-groups managed list-instances "$MIG_NAME" \
    --zone="$ZONE" \
    --format='value(instance.basename())' \
    --limit=1)"

gcloud compute ssh "$INSTANCE_NAME" \
    --zone="$ZONE"
```

Inside the VM:

```bash
stress-ng --cpu 2 --timeout 600s
```

For a more reliable test, generate load on each VM.

From Cloud Shell:

```bash
for VM in $(gcloud compute instance-groups managed list-instances "$MIG_NAME" \
    --zone="$ZONE" \
    --format='value(instance.basename())'); do

  gcloud compute ssh "$VM" \
      --zone="$ZONE" \
      --command="nohup stress-ng --cpu 2 --timeout 600s >/tmp/stress.log 2>&1 &"
done
```

Watch the group size:

```bash
watch -n 10 \
"gcloud compute instance-groups managed list-instances $MIG_NAME \
--zone=$ZONE \
--format='table(instance.basename(),instanceStatus,currentAction)'"
```

The autoscaler may take several minutes to evaluate utilization, initialize instances, and increase group size.

---

# 26. Test Autohealing

Select one managed instance:

```bash
INSTANCE_NAME="$(gcloud compute instance-groups managed list-instances "$MIG_NAME" \
    --zone="$ZONE" \
    --format='value(instance.basename())' \
    --limit=1)"
```

Stop Nginx:

```bash
gcloud compute ssh "$INSTANCE_NAME" \
    --zone="$ZONE" \
    --command="sudo systemctl stop nginx"
```

Monitor the instance group:

```bash
watch -n 10 \
"gcloud compute instance-groups managed list-instances $MIG_NAME \
--zone=$ZONE \
--format='table(instance.basename(),instanceStatus,currentAction)'"
```

After the unhealthy threshold and initial-delay conditions are considered, the MIG should attempt to repair or recreate the unhealthy VM.

---

# 27. Update a MIG Using a New Template

Because instance templates are not normally edited, create a new version.

Create a new startup script:

```bash
cat > mig-startup-v2.sh <<'EOF'
#!/bin/bash
apt-get update
apt-get install -y nginx
cat > /var/www/html/index.html <<HTML
<!DOCTYPE html>
<html>
<body>
<h1>Application Version 2</h1>
<p>Served by $(hostname)</p>
</body>
</html>
HTML
systemctl enable nginx
systemctl restart nginx
EOF
```

Create a new template:

```bash
gcloud compute instance-templates create ace-web-template-v2 \
    --machine-type=e2-micro \
    --image-family=debian-12 \
    --image-project=debian-cloud \
    --boot-disk-type=pd-balanced \
    --boot-disk-size=10GB \
    --network=default \
    --tags=http-server \
    --metadata-from-file=startup-script=mig-startup-v2.sh
```

Set the new template:

```bash
gcloud compute instance-groups managed set-instance-template "$MIG_NAME" \
    --zone="$ZONE" \
    --template=ace-web-template-v2
```

Start a rolling replacement:

```bash
gcloud compute instance-groups managed rolling-action replace "$MIG_NAME" \
    --zone="$ZONE" \
    --max-surge=1 \
    --max-unavailable=0
```

Monitor:

```bash
gcloud compute instance-groups managed list-instances "$MIG_NAME" \
    --zone="$ZONE"
```

MIGs maintain instances from the configured template and support controlled rollout of configuration updates. citeturn216546search7turn216546search14

---

# 28. Cleanup

Disable autoscaling:

```bash
gcloud compute instance-groups managed stop-autoscaling "$MIG_NAME" \
    --zone="$ZONE"
```

Delete the MIG:

```bash
gcloud compute instance-groups managed delete "$MIG_NAME" \
    --zone="$ZONE" \
    --quiet
```

Delete the health check:

```bash
gcloud compute health-checks delete "$HEALTH_CHECK_NAME" \
    --quiet
```

Delete templates:

```bash
gcloud compute instance-templates delete \
    ace-web-template-v1 \
    ace-web-template-v2 \
    --quiet
```

Delete the firewall rule if it is no longer needed:

```bash
gcloud compute firewall-rules delete allow-http \
    --quiet
```

---

# 29. ACE Exam Decision Guide

| Requirement in question | Recommended answer |
|---|---|
| Full OS-level control | Compute Engine |
| Cheap interruptible batch workers | Spot VMs |
| Centralized SSH authorization | OS Login |
| Regular disk backups | Snapshot schedule |
| Reusable configured boot environment | Custom image |
| Reusable VM configuration | Instance template |
| Automatically add/remove VMs | Autoscaled MIG |
| Replace unhealthy instances | MIG autohealing |
| Survive zonal failure | Regional MIG |
| Replicate block storage across two zones | Regional Persistent Disk |
| Independently provision storage IOPS/throughput | Hyperdisk |
| Patch a fleet of VMs | VM Manager |
| View installed OS packages across VMs | OS inventory |
| Maintain package or OS configuration | OS policies |
| Minimize disruption during host maintenance | Live migration |
| Restart after host infrastructure failure | Automatic restart |

---

# 30. Common Exam Traps

## Trap 1: Snapshot versus image

Use a snapshot for:

```text
Backup and restore of a disk
```

Use a custom image for:

```text
Creating standardized boot disks and VMs
```

## Trap 2: Instance template versus image

A custom image contains the operating-system and disk contents.

An instance template contains VM configuration and may reference an image.

```text
Custom image = what is inside the boot disk
Instance template = how the VM should be created
```

## Trap 3: Autoscaling versus autohealing

```text
Autoscaling = correct number of VMs
Autohealing = healthy VMs
```

## Trap 4: Regional disk versus snapshot

Regional Persistent Disk provides synchronous replication between zones.

A snapshot provides point-in-time backup and recovery.

## Trap 5: Spot VM for critical workloads

Spot VMs can be interrupted. They should be used only when the workload is fault-tolerant or restartable.

## Trap 6: External IP for SSH

An external IP is not always required. IAP, VPN, bastion hosts, and private connectivity can provide access to private VMs.

## Trap 7: MIG with manually configured VMs

Do not manually modify individual MIG instances as the normal deployment method. The MIG can recreate them from its template, causing manual changes to disappear.

---

# 31. Revision Summary

## Compute Engine basics

- Compute Engine provides configurable virtual machines.
- Machine types define CPU and memory.
- Custom machine types reduce overprovisioning.
- Boot disks contain the operating system.
- Persistent Disk provides durable network block storage.
- Regional disks replicate between two zones.
- Hyperdisk provides modern, configurable storage performance.
- OS Login centralizes SSH access through IAM.
- Availability policies control maintenance and restart behavior.
- Spot VMs provide lower-cost interruptible compute.

## Compute Engine operations

- Snapshots protect disk data.
- Snapshot schedules automate backups.
- Custom images provide standardized boot environments.
- VM Manager handles OS patching, inventory, and policies.
- Instance templates define repeatable VM configurations.
- MIGs operate groups of identical VMs.
- Autoscaling changes group size.
- Health checks support traffic management and autohealing.
- Regional MIGs provide better zonal-failure resilience.
:::

The labs use replaceable names and variables, so they can be executed independently in a practice project.
