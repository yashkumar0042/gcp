In Google Cloud Platform (GCP), you can create a common disk and attach it to multiple VM instances by following these steps:

### 1. Create a Disk:

Use the `gcloud` command-line tool or the GCP Console to create a persistent disk. Specify the size, type, and other options as needed.

```bash
gcloud compute disks create common-disk --size=100GB --zone=us-central1-a
```

Replace `us-central1-a` with the desired zone for your disk.

### 2. Attach the Disk to VM Instances:

You can attach the created disk to multiple VM instances when creating the instances or later as needed.

#### a. During VM Instance Creation:

```bash
gcloud compute instances create instance-1 --disk=name=common-disk,device-name=common-disk --zone=us-central1-a
gcloud compute instances create instance-2 --disk=name=common-disk,device-name=common-disk --zone=us-central1-a
```

This command creates two instances (`instance-1` and `instance-2`) and attaches the `common-disk` to each of them.

#### b. After VM Instance Creation:

If you want to attach the disk to existing instances, use the following commands:

```bash
gcloud compute instances attach-disk instance-1 --disk=common-disk --zone=us-central1-a
gcloud compute instances attach-disk instance-2 --disk=common-disk --zone=us-central1-a
```

Replace `instance-1` and `instance-2` with the names of your VM instances.

### 3. Mount the Disk on VM Instances:

After attaching the disk to VM instances, you need to mount the disk within each VM. Connect to each VM using SSH and perform the following steps:

#### a. Identify the Disk:

```bash
lsblk
```

Identify the disk device, usually `/dev/sdb` or a similar identifier.

#### b. Create a Mount Point:

```bash
sudo mkdir /mnt/common-disk
```

#### c. Mount the Disk:

```bash
sudo mount /dev/sdb /mnt/common-disk
```

Replace `/dev/sdb` with the actual disk device you identified.

### 4. Configure Auto-Mount (Optional):

To ensure that the disk is mounted automatically after each VM restart, you can update the `/etc/fstab` file.

```bash
echo '/dev/sdb /mnt/common-disk ext4 defaults 0 0' | sudo tee -a /etc/fstab
```

Replace `/dev/sdb` and `/mnt/common-disk` with your actual disk device and mount point.

Now, the common disk should be attached and mounted on multiple VM instances in GCP. Adjust the commands and configurations based on your specific requirements and operating system.
