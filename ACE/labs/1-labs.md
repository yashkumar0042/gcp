
### 1. **Instances:**
   - **GUI:**
     1. In the Google Cloud Console, navigate to "Compute Engine" > "VM instances."
     2. Click the "Create Instance" button.
     3. Enter a unique name for the instance.
     4. Choose a region and zone.
     5. Under "Machine type," select the desired machine type.
     6. Under "Boot disk," choose an operating system and disk size.
     7. (Optional) Configure additional options such as adding GPUs or enabling advanced settings.
     8. Click the "Create" button to launch the instance.
  - **CLI:**
     ```bash
     gcloud compute instances create my-instance \
         --machine-type n1-standard-2 \
         --image-family debian-10 \
         --image-project debian-cloud \
         --zone us-central1-a
     ```
     

### 2. **Networks:**
   - **GUI:**
     1. In the Google Cloud Console, navigate to "VPC network" > "VPC networks."
     2. Click the "Create VPC network" button.
     3. Enter a name for the VPC network.
     4. (Optional) Configure subnets, firewall rules, and routes.
     5. Click the "Create" button.
  - **CLI:**
     ```bash
     gcloud compute networks create my-network
     gcloud compute networks subnets create my-subnet \
         --network my-network \
         --range 10.0.0.0/24
     ```
### 3. **Disks and Images:**
   - **GUI:**
     1. In the Google Cloud Console, navigate to "Compute Engine" > "Disks."
     2. Click the "Create Disk" button.
     3. Enter a name for the disk.
     4. Choose a zone and specify the size.
     5. Click the "Create" button.
     6. To create a custom image, navigate to "Compute Engine" > "Images."
     7. Click the "Create Image" button.
     8. Choose the source disk and provide a name for the image.
     9. Click the "Create" button.
  - **CLI:**
     ```bash
     gcloud compute disks create my-disk \
         --size 100GB \
         --type pd-standard \
         --zone us-central1-a
     gcloud compute images create my-image \
         --source-disk my-disk \
         --source-disk-zone us-central1-a
     ```
### 4. **Authorization:**
   - **GUI:**
     1. In the Google Cloud Console, navigate to "IAM & Admin" > "IAM."
     2. Click the "+ Add" button.
     3. Enter the email address of the user or service account.
     4. Choose the desired role (e.g., Project > Owner).
     5. Click the "Save" button.
  - **CLI:**
     ```bash
     gcloud projects add-iam-policy-binding my-project \
         --member=user:jane.doe@example.com \
         --role=roles/editor
     ```
### 5. **Snapshots:**
   - **GUI:**
     1. In the Google Cloud Console, navigate to "Compute Engine" > "Snapshots."
     2. Click the "Create Snapshot" button.
     3. Enter a name for the snapshot.
     4. Choose the source disk.
     5. Configure additional options if needed.
     6. Click the "Create" button.
  - **CLI:**
     ```bash
     gcloud compute disks snapshot my-disk \
         --snapshot-name my-snapshot \
         --zone us-central1-a
     ```
### 6. **Google Cloud Storage:**
   - **GUI:**
     1. In the Google Cloud Console, navigate to "Storage" > "Browser."
     2. Click the "+ Create Bucket" button.
     3. Enter a globally unique name for the bucket.
     4. Choose a default storage class.
     5. Click the "Create" button.
     6. To upload a file, select the bucket, click the "Upload Files" button, and choose the file.
  - **CLI:**
     ```bash
     gsutil mb gs://my-bucket
     gsutil cp local-file.txt gs://my-bucket
     ```
### 7. **Instance Groups:**
   - **GUI:**
     1. In the Google Cloud Console, navigate to "Compute Engine" > "Instance groups."
     2. Click the "Create Instance Group" button.
     3. Enter a name for the instance group.
     4. Specify the instance template, zone, and autoscaling settings.
     5. Click the "Create" button.
- **CLI:**
     ```bash
     gcloud compute instance-groups managed create my-group \
         --base-instance-name my-instance \
         --size 3 \
         --zone us-central1-a
     ```
### 8. **Google Cloud SQL:**
   - **GUI:**
     1. In the Google Cloud Console, navigate to "SQL."
     2. Click the "Create Instance" button.
     3. Choose the database engine (e.g., MySQL).
     4. Configure instance details, including region, machine type, and root password.
     5. Click the "Create" button.
  - **CLI:**
     ```bash
     gcloud sql instances create my-sql-instance \
         --database-version MYSQL_5_7 \
         --tier db-n1-standard-1 \
         --region us-central1
     ```
### 9. **Metadata & Startup and Shutdown Scripts:**
   - **GUI:**
     1. In the Google Cloud Console, navigate to "Compute Engine" > "VM instances."
     2. Click the "Edit" button for the instance.
     3. Scroll down to the "Custom metadata" section.
     4. Add key-value pairs as needed.
     5. Scroll down to the "Custom metadata" section.
     6. Add startup and shutdown scripts if needed.
     7. Click the "Save" button.
  - **CLI:**
     ```bash
     gcloud compute instances add-metadata my-instance \
         --metadata key1=value1,key2=value2
     ```
