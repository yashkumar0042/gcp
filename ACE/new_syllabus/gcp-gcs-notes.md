# Google Cloud Storage (GCS) — Complete GitHub Notes

> A practical, exam-friendly, and production-oriented guide to Google Cloud Storage, covering concepts, Google Cloud Console steps, `gcloud storage`, `gsutil`, IAM, security, lifecycle management, versioning, retention, encryption, transfers, monitoring, troubleshooting, and hands-on labs.

---

## Table of Contents

1. [What is Google Cloud Storage?](#1-what-is-google-cloud-storage)
2. [Core Architecture](#2-core-architecture)
3. [Buckets](#3-buckets)
4. [Objects](#4-objects)
5. [Locations](#5-locations)
6. [Storage Classes](#6-storage-classes)
7. [Cloud Storage Pricing Concepts](#7-cloud-storage-pricing-concepts)
8. [Authentication and Initial Setup](#8-authentication-and-initial-setup)
9. [Create and Manage Buckets](#9-create-and-manage-buckets)
10. [Upload, Download, Copy, Move, and Delete Objects](#10-upload-download-copy-move-and-delete-objects)
11. [Folders, Managed Folders, and Hierarchical Namespace](#11-folders-managed-folders-and-hierarchical-namespace)
12. [IAM and Access Control](#12-iam-and-access-control)
13. [Uniform Bucket-Level Access](#13-uniform-bucket-level-access)
14. [Public Access Prevention](#14-public-access-prevention)
15. [Make Objects Public](#15-make-objects-public)
16. [Signed URLs](#16-signed-urls)
17. [Object Versioning](#17-object-versioning)
18. [Soft Delete](#18-soft-delete)
19. [Object Lifecycle Management](#19-object-lifecycle-management)
20. [Autoclass](#20-autoclass)
21. [Retention Policies and Object Holds](#21-retention-policies-and-object-holds)
22. [Encryption](#22-encryption)
23. [CORS](#23-cors)
24. [Requester Pays](#24-requester-pays)
25. [Website Hosting](#25-website-hosting)
26. [Data Transfer Options](#26-data-transfer-options)
27. [Notifications and Event-Driven Processing](#27-notifications-and-event-driven-processing)
28. [Logging, Monitoring, and Audit](#28-logging-monitoring-and-audit)
29. [Performance and Reliability](#29-performance-and-reliability)
30. [Common IAM Roles](#30-common-iam-roles)
31. [Terraform Example](#31-terraform-example)
32. [Complete GUI Lab](#32-complete-gui-lab)
33. [Complete CLI Lab](#33-complete-cli-lab)
34. [Static Website Lab](#34-static-website-lab)
35. [Lifecycle and Versioning Lab](#35-lifecycle-and-versioning-lab)
36. [Signed URL Lab](#36-signed-url-lab)
37. [Troubleshooting](#37-troubleshooting)
38. [ACE Exam Notes](#38-ace-exam-notes)
39. [Practice Questions](#39-practice-questions)
40. [Cleanup](#40-cleanup)
41. [Official Documentation](#41-official-documentation)

---

# 1. What is Google Cloud Storage?

Google Cloud Storage is Google Cloud's managed **object storage** service.

It stores data as:

```text
Project
└── Bucket
    ├── Object
    ├── Object
    └── Object
```

Typical use cases:

- Images, videos, PDFs, and application files
- Backups and archives
- Data lake storage
- BigQuery or analytics staging data
- Machine learning datasets
- Static website content
- Software packages and build artifacts
- Log archives
- Disaster-recovery copies
- Data exchange between applications

Cloud Storage is **not**:

- A block storage disk such as Persistent Disk
- A traditional NFS file server
- A relational database
- A boot disk for a VM
- A transactional file system

## Object storage characteristics

An object contains:

```text
Object data + Object name + Metadata
```

For example:

```text
gs://company-prod-reports/finance/2026/july/report.csv
```

Where:

- `company-prod-reports` is the bucket
- `finance/2026/july/report.csv` is the object name
- `gs://` is the Cloud Storage URI scheme

---

# 2. Core Architecture

## Main resources

| Resource | Description |
|---|---|
| Project | Billing, IAM, API, and administrative boundary |
| Bucket | Top-level container for objects |
| Object | Immutable data stored inside a bucket |
| Object generation | Unique version number assigned when object data changes |
| Metadata | Properties such as content type, cache control, labels, and custom metadata |
| Managed folder | IAM-manageable folder-like resource |
| Anywhere Cache / Rapid Cache | Optional caching capabilities for supported use cases |
| Storage Insights | Inventory and analytical insights for storage estates |

## Important behavior

Cloud Storage objects are generally treated as immutable blobs.

When an object is overwritten:

- New object data is written.
- The object's generation changes.
- The old generation may remain if Object Versioning is enabled.
- Preconditions can be used to prevent accidental overwrites.

---

# 3. Buckets

A bucket is the primary container for Cloud Storage objects.

## Bucket properties

A bucket has:

- A globally unique name
- A location
- A default storage class
- IAM policy
- Public access configuration
- Uniform bucket-level access setting
- Soft delete policy
- Lifecycle rules
- Versioning setting
- Retention policy
- Encryption configuration
- Labels
- Logging configuration
- CORS configuration
- Website configuration

## Bucket naming rules

A bucket name must generally:

- Be globally unique across all Google Cloud customers
- Use lowercase letters, numbers, hyphens, underscores, or dots
- Begin and end with a letter or number
- Not contain spaces
- Avoid sensitive information
- Avoid names resembling an IP address

Recommended format:

```text
company-environment-purpose-random
```

Example:

```text
kubekode-prod-video-assets-202607
```

## Bucket names are globally unique

The following can exist only once globally:

```text
gs://my-company-backups
```

Another project cannot create a bucket with the same name.

## Bucket name best practices

Avoid:

```text
tushar-personal-bank-documents
production-password-backups
customer-aadhaar-data
```

Prefer:

```text
kk-prod-app-assets-a91f
```

---

# 4. Objects

An object is the actual data stored in a bucket.

Examples:

```text
gs://my-bucket/image.png
gs://my-bucket/logs/app.log
gs://my-bucket/backups/database.sql.gz
```

## Object components

- Object name
- Data
- Content type
- Content encoding
- Cache control
- Custom metadata
- Storage class
- Creation timestamp
- Update timestamp
- Generation
- Metageneration
- Checksums

## Object size

Cloud Storage supports individual objects up to **5 TiB**.

## Object names

Cloud Storage can store `/` in object names:

```text
logs/2026/07/13/app.log
```

In a standard flat namespace bucket, this is still one object name. The slashes only create a folder-like presentation.

---

# 5. Locations

The bucket location determines where object data is physically stored.

## Location types

### Region

Data is stored in one region.

Examples:

```text
asia-south1
us-central1
europe-west1
```

Use when:

- Compute resources are in the same region
- Low latency is important
- Data residency requires a specific region
- You want predictable regional design

### Dual-region

Data is stored across two selected regions.

Use when:

- Higher availability is required
- You need geographic redundancy
- Workloads run across two regions

### Multi-region

Data is stored within a broad geographic area.

Examples:

```text
ASIA
EU
US
```

Use when:

- Users or workloads are geographically distributed
- Geographic redundancy is important
- Exact regional placement is less important

## Location selection guidance

Choose a bucket location near the primary workload.

Example:

```text
GKE cluster: asia-south1
Cloud Storage bucket: asia-south1
```

This can help reduce latency and avoid unnecessary network charges.

## Location cannot normally be changed in place

To move data to another location:

1. Create a new bucket in the required location.
2. Copy or transfer objects.
3. Validate the data.
4. Update applications.
5. Delete the old bucket when safe.

---

# 6. Storage Classes

Storage classes are primarily pricing and access-frequency choices.

## Main storage classes

| Storage class | Best for | Minimum storage duration |
|---|---|---:|
| Standard | Frequently accessed data | None |
| Nearline | Accessed about once per month | 30 days |
| Coldline | Accessed about once per quarter | 90 days |
| Archive | Rarely accessed, long-term retention | 365 days |

> Availability and durability are not reduced merely because a colder storage class is selected. The major differences are storage price, retrieval cost, operation cost, and minimum storage duration.

## Standard Storage

Use for:

- Active website content
- Data pipelines
- Frequently accessed media
- Mobile and web application files
- Current analytics datasets

## Nearline Storage

Use for:

- Monthly backups
- Disaster recovery
- Infrequently accessed files
- Monthly reporting archives

## Coldline Storage

Use for:

- Quarterly disaster-recovery testing
- Long-term backups
- Compliance data accessed occasionally

## Archive Storage

Use for:

- Regulatory archives
- Long-term backup
- Data rarely retrieved
- Historical records

## Minimum storage duration

Deleting or replacing an object before its minimum duration can cause an early deletion charge.

Example:

```text
Archive object deleted after 20 days
```

You may still be charged based on the remaining portion of the 365-day minimum duration.

## Default storage class

The bucket's default class applies to newly created objects unless another class is explicitly selected.

## Change object storage class

Changing an existing object's class generally involves rewriting the object or using lifecycle management.

```bash
gcloud storage objects update gs://BUCKET_NAME/path/file.txt \
  --storage-class=NEARLINE
```

For large-scale automatic transitions, use lifecycle rules or Autoclass.

---

# 7. Cloud Storage Pricing Concepts

Cloud Storage billing can include:

- Data storage
- Data processing operations
- Data retrieval
- Network data transfer
- Early deletion charges
- Replication-related costs
- Management features, depending on configuration

## Operation categories

Operations may be categorized into classes such as:

- Class A operations
- Class B operations
- Free operations

Examples:

- Creating buckets
- Listing objects
- Uploading data
- Reading object metadata
- Downloading object data
- Rewriting objects

Always check the current pricing page before production cost estimates.

## Cost optimization

- Select the correct location.
- Select the correct storage class.
- Use lifecycle rules.
- Use Autoclass when access patterns are unpredictable.
- Delete obsolete object versions.
- Configure soft delete duration intentionally.
- Avoid unnecessary cross-region transfers.
- Use retention only when required.
- Review incomplete uploads and abandoned data.
- Use inventory and monitoring for large storage estates.

---

# 8. Authentication and Initial Setup

## Set environment variables

```bash
export PROJECT_ID="your-project-id"
export REGION="asia-south1"
export BUCKET_NAME="${PROJECT_ID}-gcs-lab-$(date +%s)"
```

PowerShell:

```powershell
$env:PROJECT_ID="your-project-id"
$env:REGION="asia-south1"
$env:BUCKET_NAME="$env:PROJECT_ID-gcs-lab-$(Get-Date -UFormat %s)"
```

## Authenticate

```bash
gcloud auth login
```

For Application Default Credentials:

```bash
gcloud auth application-default login
```

## Set project

```bash
gcloud config set project "$PROJECT_ID"
```

Verify:

```bash
gcloud config list
gcloud projects describe "$PROJECT_ID"
```

## Enable Cloud Storage API

```bash
gcloud services enable storage.googleapis.com
```

Verify:

```bash
gcloud services list --enabled \
  --filter="NAME:storage.googleapis.com"
```

## Check active account

```bash
gcloud auth list
```

---

# 9. Create and Manage Buckets

## GUI: Create a bucket

1. Open Google Cloud Console.
2. Navigate to **Cloud Storage → Buckets**.
3. Click **Create**.
4. Enter a globally unique bucket name.
5. Select location type:
   - Region
   - Dual-region
   - Multi-region
6. Select the location.
7. Select a default storage class.
8. Configure access control:
   - Uniform bucket-level access is generally recommended.
9. Configure public access prevention.
10. Configure data protection:
    - Soft delete
    - Versioning
    - Retention policy
11. Select encryption:
    - Google-managed encryption
    - Customer-managed encryption key
12. Click **Create**.

## CLI: Create a regional bucket

```bash
gcloud storage buckets create "gs://$BUCKET_NAME" \
  --project="$PROJECT_ID" \
  --location="$REGION" \
  --default-storage-class=STANDARD \
  --uniform-bucket-level-access
```

## Create a Nearline bucket

```bash
gcloud storage buckets create "gs://$BUCKET_NAME" \
  --location="$REGION" \
  --default-storage-class=NEARLINE \
  --uniform-bucket-level-access
```

## Enforce public access prevention

```bash
gcloud storage buckets update "gs://$BUCKET_NAME" \
  --public-access-prevention
```

## View buckets

```bash
gcloud storage buckets list
```

Specific project:

```bash
gcloud storage buckets list --project="$PROJECT_ID"
```

## Describe a bucket

```bash
gcloud storage buckets describe "gs://$BUCKET_NAME"
```

JSON output:

```bash
gcloud storage buckets describe "gs://$BUCKET_NAME" \
  --format=json
```

Selected properties:

```bash
gcloud storage buckets describe "gs://$BUCKET_NAME" \
  --format="yaml(name,location,storageClass,iamConfiguration,versioning,lifecycle)"
```

## Add labels

```bash
gcloud storage buckets update "gs://$BUCKET_NAME" \
  --update-labels=environment=dev,team=platform,purpose=training
```

## Remove a label

```bash
gcloud storage buckets update "gs://$BUCKET_NAME" \
  --remove-labels=purpose
```

## Change default storage class

```bash
gcloud storage buckets update "gs://$BUCKET_NAME" \
  --default-storage-class=NEARLINE
```

This affects newly written objects. Existing objects retain their current storage class unless rewritten or transitioned.

## Delete an empty bucket

```bash
gcloud storage buckets delete "gs://$BUCKET_NAME"
```

## Delete bucket and all objects

```bash
gcloud storage rm --recursive "gs://$BUCKET_NAME"
```

Use with extreme caution.

---

# 10. Upload, Download, Copy, Move, and Delete Objects

## Create sample files

```bash
mkdir -p gcs-demo/logs
echo "Hello from Google Cloud Storage" > gcs-demo/hello.txt
echo '{"service":"api","status":"ok"}' > gcs-demo/logs/app.json
```

## GUI: Upload files

1. Open **Cloud Storage → Buckets**.
2. Select the bucket.
3. Open the **Objects** tab.
4. Click **Upload files** or drag and drop files.
5. Verify the uploaded objects.

## Upload one file

```bash
gcloud storage cp gcs-demo/hello.txt "gs://$BUCKET_NAME/"
```

## Upload and rename

```bash
gcloud storage cp gcs-demo/hello.txt \
  "gs://$BUCKET_NAME/documents/greeting.txt"
```

## Upload a directory recursively

```bash
gcloud storage cp --recursive gcs-demo "gs://$BUCKET_NAME/"
```

## Upload with content type

```bash
gcloud storage cp index.html "gs://$BUCKET_NAME/" \
  --content-type="text/html"
```

## Upload with cache control

```bash
gcloud storage cp app.js "gs://$BUCKET_NAME/assets/app.js" \
  --cache-control="public,max-age=3600"
```

## List objects

```bash
gcloud storage ls "gs://$BUCKET_NAME"
```

Recursive listing:

```bash
gcloud storage ls --recursive "gs://$BUCKET_NAME/**"
```

Modern objects command:

```bash
gcloud storage objects list "gs://$BUCKET_NAME"
```

## Describe an object

```bash
gcloud storage objects describe \
  "gs://$BUCKET_NAME/hello.txt"
```

## Download an object

```bash
gcloud storage cp \
  "gs://$BUCKET_NAME/hello.txt" \
  ./downloaded-hello.txt
```

## Download recursively

```bash
gcloud storage cp --recursive \
  "gs://$BUCKET_NAME/gcs-demo" \
  ./downloaded-data
```

## Copy an object within a bucket

```bash
gcloud storage cp \
  "gs://$BUCKET_NAME/hello.txt" \
  "gs://$BUCKET_NAME/archive/hello.txt"
```

## Copy between buckets

```bash
gcloud storage cp \
  "gs://SOURCE_BUCKET/path/file.txt" \
  "gs://DESTINATION_BUCKET/path/file.txt"
```

## Move an object

```bash
gcloud storage mv \
  "gs://$BUCKET_NAME/hello.txt" \
  "gs://$BUCKET_NAME/processed/hello.txt"
```

A move is logically a copy/rewrite followed by deletion unless supported by a specialized operation.

## Rename an object

Cloud Storage does not have a traditional file rename in a flat namespace. Use move:

```bash
gcloud storage mv \
  "gs://$BUCKET_NAME/old-name.txt" \
  "gs://$BUCKET_NAME/new-name.txt"
```

## Delete an object

```bash
gcloud storage rm "gs://$BUCKET_NAME/processed/hello.txt"
```

## Delete objects recursively

```bash
gcloud storage rm --recursive \
  "gs://$BUCKET_NAME/logs/"
```

## Synchronize a directory

Local to bucket:

```bash
gcloud storage rsync --recursive \
  ./website \
  "gs://$BUCKET_NAME/website"
```

Bucket to local:

```bash
gcloud storage rsync --recursive \
  "gs://$BUCKET_NAME/website" \
  ./website-backup
```

Delete extra destination files:

```bash
gcloud storage rsync --recursive --delete-unmatched-destination-objects \
  ./website \
  "gs://$BUCKET_NAME/website"
```

Be careful: this can delete destination objects not found in the source.

## Compose objects

```bash
echo "Part 1" > part1.txt
echo "Part 2" > part2.txt

gcloud storage cp part1.txt part2.txt "gs://$BUCKET_NAME/parts/"

gcloud storage objects compose \
  "gs://$BUCKET_NAME/parts/part1.txt" \
  "gs://$BUCKET_NAME/parts/part2.txt" \
  "gs://$BUCKET_NAME/combined.txt"
```

## Checksums

Cloud Storage uses checksums to detect corruption, including CRC32C and, in some situations, MD5.

Describe object metadata:

```bash
gcloud storage objects describe \
  "gs://$BUCKET_NAME/combined.txt" \
  --format="yaml(name,size,crc32c,md5Hash)"
```

---

# 11. Folders, Managed Folders, and Hierarchical Namespace

## Simulated folders

In flat namespace buckets:

```text
logs/2026/app.log
```

is an object name. `logs/2026/` is a prefix, not a traditional directory.

## Managed folders

Managed folders provide IAM-manageable folder-like resources.

Use managed folders when:

- Different teams need access to different prefixes.
- You want folder-level IAM.
- You want to organize large shared data sets.

Managed folders require compatible bucket access configuration, including uniform bucket-level access.

## Hierarchical namespace

Hierarchical namespace adds stronger file-system-like folder semantics.

It is useful for:

- Analytics workloads
- Hadoop and Spark ecosystems
- File-system-style organization
- Atomic folder operations
- Workloads using Cloud Storage FUSE

Create a hierarchical namespace bucket:

```bash
gcloud storage buckets create "gs://$BUCKET_NAME" \
  --location="$REGION" \
  --uniform-bucket-level-access \
  --enable-hierarchical-namespace
```

Review regional and feature compatibility before enabling it.

---

# 12. IAM and Access Control

Cloud Storage authorization can involve:

- Project-level IAM
- Bucket-level IAM
- Managed-folder IAM
- ACLs, when uniform bucket-level access is disabled
- Organization policies
- Public access prevention
- VPC Service Controls
- Signed URLs
- Service account impersonation

## Principle of least privilege

Grant the smallest role at the narrowest scope.

Bad:

```text
Project-level Owner
```

Better:

```text
Bucket-level Storage Object Viewer
```

## Add IAM role to a user

```bash
gcloud storage buckets add-iam-policy-binding "gs://$BUCKET_NAME" \
  --member="user:user@example.com" \
  --role="roles/storage.objectViewer"
```

## Add IAM role to a service account

```bash
gcloud storage buckets add-iam-policy-binding "gs://$BUCKET_NAME" \
  --member="serviceAccount:app-sa@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/storage.objectCreator"
```

## View IAM policy

```bash
gcloud storage buckets get-iam-policy "gs://$BUCKET_NAME"
```

## Remove IAM binding

```bash
gcloud storage buckets remove-iam-policy-binding "gs://$BUCKET_NAME" \
  --member="user:user@example.com" \
  --role="roles/storage.objectViewer"
```

## Common application pattern

Uploader service account:

```text
roles/storage.objectCreator
```

Reader service account:

```text
roles/storage.objectViewer
```

Operations service account needing modification and deletion:

```text
roles/storage.objectAdmin
```

Avoid giving the uploader `objectAdmin` unless it must overwrite or delete objects.

---

# 13. Uniform Bucket-Level Access

Uniform bucket-level access disables bucket and object ACL-based permissions.

Access is managed only through IAM.

## Benefits

- Simpler authorization
- Reduced risk from object ACLs
- Consistent access control
- Required by several advanced features
- Better organizational governance

## Enable

```bash
gcloud storage buckets update "gs://$BUCKET_NAME" \
  --uniform-bucket-level-access
```

## Check

```bash
gcloud storage buckets describe "gs://$BUCKET_NAME" \
  --format="value(iamConfiguration.uniformBucketLevelAccess.enabled)"
```

## Disable

```bash
gcloud storage buckets update "gs://$BUCKET_NAME" \
  --no-uniform-bucket-level-access
```

Restrictions can apply after uniform access has been enabled for an extended period. Do not assume it can always be disabled later.

---

# 14. Public Access Prevention

Public access prevention blocks access granted through:

```text
allUsers
allAuthenticatedUsers
```

## Enforce

```bash
gcloud storage buckets update "gs://$BUCKET_NAME" \
  --public-access-prevention
```

## Inherit project or organization setting

```bash
gcloud storage buckets update "gs://$BUCKET_NAME" \
  --no-public-access-prevention
```

This does not necessarily make the bucket public. It removes bucket-level enforcement so inherited policy applies.

## Recommended production pattern

```text
Uniform bucket-level access: Enabled
Public access prevention: Enforced
Access: IAM or signed URLs
```

---

# 15. Make Objects Public

Public access should be used only for intentionally public content.

## Bucket-level public read

```bash
gcloud storage buckets add-iam-policy-binding "gs://$BUCKET_NAME" \
  --member="allUsers" \
  --role="roles/storage.objectViewer"
```

This fails or is ineffective if public access prevention is enforced.

## Remove public access

```bash
gcloud storage buckets remove-iam-policy-binding "gs://$BUCKET_NAME" \
  --member="allUsers" \
  --role="roles/storage.objectViewer"
```

## Public URL format

```text
https://storage.googleapis.com/BUCKET_NAME/OBJECT_NAME
```

Example:

```text
https://storage.googleapis.com/example-bucket/images/logo.png
```

## Security warning

Never make a bucket public to solve a temporary permission problem. Use:

- Correct IAM
- Signed URLs
- Authenticated URLs
- Service accounts

---

# 16. Signed URLs

A signed URL provides time-limited access to a specific object.

Use cases:

- Temporary download links
- Temporary upload links
- Sharing private files
- Browser upload directly to Cloud Storage
- Avoiding permanent public access

Anyone with the signed URL can use it until expiry.

## Create a V4 signed URL

```bash
gcloud storage sign-url \
  "gs://$BUCKET_NAME/private/report.pdf" \
  --duration=15m
```

Using a service account key:

```bash
gcloud storage sign-url \
  "gs://$BUCKET_NAME/private/report.pdf" \
  --private-key-file=service-account-key.json \
  --duration=15m
```

Prefer keyless signing or service account impersonation where supported. Long-lived service account keys create security risk.

## Signed upload URL

An application can generate a signed `PUT` URL. A client can then upload directly to Cloud Storage without receiving broad bucket permissions.

---

# 17. Object Versioning

Object Versioning preserves noncurrent versions when an object is replaced or deleted.

## Enable versioning

```bash
gcloud storage buckets update "gs://$BUCKET_NAME" \
  --versioning
```

## Check versioning

```bash
gcloud storage buckets describe "gs://$BUCKET_NAME" \
  --format="value(versioning.enabled)"
```

## Upload multiple versions

```bash
echo "version 1" > config.txt
gcloud storage cp config.txt "gs://$BUCKET_NAME/config.txt"

echo "version 2" > config.txt
gcloud storage cp config.txt "gs://$BUCKET_NAME/config.txt"
```

## List all generations

```bash
gcloud storage ls --all-versions \
  "gs://$BUCKET_NAME/config.txt"
```

## Restore an older generation

First find the generation:

```bash
gcloud storage ls --all-versions \
  "gs://$BUCKET_NAME/config.txt"
```

Then copy that generation:

```bash
gcloud storage cp \
  "gs://$BUCKET_NAME/config.txt#GENERATION_NUMBER" \
  "gs://$BUCKET_NAME/config-restored.txt"
```

## Disable versioning

```bash
gcloud storage buckets update "gs://$BUCKET_NAME" \
  --no-versioning
```

Disabling versioning does not automatically delete old versions.

## Cost warning

Old versions consume storage and can accumulate silently. Add a lifecycle rule to delete noncurrent versions after a defined period.

---

# 18. Soft Delete

Soft delete retains deleted objects and buckets for a configured duration so they can be restored.

New buckets can have a default soft delete retention period depending on current platform defaults.

## Why use soft delete?

- Recover from accidental deletion
- Recover from application bugs
- Mitigate destructive automation
- Provide a recovery window

## Considerations

- Retained soft-deleted data can incur storage costs.
- It is not a replacement for independent backup.
- Configure the duration according to recovery objectives and cost.
- Retention policies and object holds can interact with deletion behavior.

Describe bucket protection settings:

```bash
gcloud storage buckets describe "gs://$BUCKET_NAME" \
  --format=json
```

Use the current CLI help to confirm available soft delete flags:

```bash
gcloud storage buckets update --help
```

---

# 19. Object Lifecycle Management

Lifecycle management automatically performs actions when objects match conditions.

## Common actions

- Delete
- SetStorageClass
- AbortIncompleteMultipartUpload

## Common conditions

- Age
- CreatedBefore
- DaysSinceCustomTime
- DaysSinceNoncurrentTime
- IsLive
- MatchesStorageClass
- MatchesPrefix
- MatchesSuffix
- NoncurrentTimeBefore
- NumNewerVersions

## Example: delete objects after 30 days

Create `lifecycle.json`:

```json
{
  "rule": [
    {
      "action": {
        "type": "Delete"
      },
      "condition": {
        "age": 30
      }
    }
  ]
}
```

Apply:

```bash
gcloud storage buckets update "gs://$BUCKET_NAME" \
  --lifecycle-file=lifecycle.json
```

## Example: Standard → Nearline → Coldline → Delete

```json
{
  "rule": [
    {
      "action": {
        "type": "SetStorageClass",
        "storageClass": "NEARLINE"
      },
      "condition": {
        "age": 30,
        "matchesStorageClass": [
          "STANDARD"
        ]
      }
    },
    {
      "action": {
        "type": "SetStorageClass",
        "storageClass": "COLDLINE"
      },
      "condition": {
        "age": 90,
        "matchesStorageClass": [
          "NEARLINE"
        ]
      }
    },
    {
      "action": {
        "type": "Delete"
      },
      "condition": {
        "age": 365
      }
    }
  ]
}
```

Apply:

```bash
gcloud storage buckets update "gs://$BUCKET_NAME" \
  --lifecycle-file=lifecycle.json
```

## Delete old noncurrent versions

```json
{
  "rule": [
    {
      "action": {
        "type": "Delete"
      },
      "condition": {
        "isLive": false,
        "numNewerVersions": 3
      }
    },
    {
      "action": {
        "type": "Delete"
      },
      "condition": {
        "isLive": false,
        "daysSinceNoncurrentTime": 30
      }
    }
  ]
}
```

## View lifecycle configuration

```bash
gcloud storage buckets describe "gs://$BUCKET_NAME" \
  --format="json(lifecycle)"
```

## Remove lifecycle configuration

Create an empty configuration:

```json
{
  "rule": []
}
```

Then apply it.

## Important behavior

Lifecycle actions are asynchronous. An object becoming eligible does not guarantee immediate action at the exact eligibility timestamp.

---

# 20. Autoclass

Autoclass automatically moves objects between storage classes based on access patterns.

Use it when:

- Access frequency is unpredictable.
- Manually designed lifecycle rules are difficult.
- A bucket contains mixed hot and cold data.
- You want automated storage-class optimization.

Do not combine Autoclass with assumptions that every object will remain in one manually selected class.

Review current eligibility, terminal storage class behavior, pricing, and update restrictions before enabling.

---

# 21. Retention Policies and Object Holds

Retention controls prevent object deletion or replacement for a required period.

## Bucket retention policy

Example concept:

```text
Retention period: 30 days
```

An object cannot be deleted or overwritten until it has satisfied the retention duration.

## Create bucket with retention

```bash
gcloud storage buckets create "gs://$BUCKET_NAME" \
  --location="$REGION" \
  --uniform-bucket-level-access \
  --retention-period=30d
```

## Update retention period

```bash
gcloud storage buckets update "gs://$BUCKET_NAME" \
  --retention-period=90d
```

## Lock retention policy

```bash
gcloud storage buckets update "gs://$BUCKET_NAME" \
  --lock-retention-period
```

> Locking is irreversible. Confirm legal, compliance, and operational requirements first.

## Object holds

### Temporary hold

A temporary hold prevents deletion until the hold is released.

### Event-based hold

An event-based hold prevents deletion until an external event occurs and the hold is released. The retention timer can then be calculated using the event-based retention timestamp.

Use cases:

- Legal hold
- Regulatory workflow
- Records management
- Data awaiting external approval

---

# 22. Encryption

Cloud Storage encrypts data at rest by default.

## Encryption options

### Google-managed encryption keys

Default option.

Google manages encryption keys and rotation.

### Customer-managed encryption keys

Keys are stored in Cloud KMS.

Use when:

- Compliance requires customer control
- Key access must be audited separately
- Key rotation and revocation require explicit control

High-level setup:

1. Create a Cloud KMS key ring.
2. Create a crypto key.
3. Grant the Cloud Storage service agent permission to use the key.
4. Configure the bucket's default KMS key.
5. Upload objects.

Example:

```bash
gcloud storage buckets update "gs://$BUCKET_NAME" \
  --default-encryption-key="projects/$PROJECT_ID/locations/$REGION/keyRings/gcs-ring/cryptoKeys/gcs-key"
```

### Customer-supplied encryption keys

The customer supplies key material per request.

This creates significant operational responsibility. Losing the key can make data unrecoverable.

## Encryption in transit

Clients access Cloud Storage using HTTPS/TLS endpoints.

---

# 23. CORS

Cross-Origin Resource Sharing allows browser applications from one origin to access Cloud Storage resources from another origin.

Example:

```text
Frontend: https://app.example.com
Object:   https://storage.googleapis.com/example-bucket/image.png
```

## Create `cors.json`

```json
[
  {
    "origin": [
      "https://app.example.com"
    ],
    "method": [
      "GET",
      "HEAD",
      "PUT"
    ],
    "responseHeader": [
      "Content-Type",
      "ETag"
    ],
    "maxAgeSeconds": 3600
  }
]
```

## Apply CORS

```bash
gcloud storage buckets update "gs://$BUCKET_NAME" \
  --cors-file=cors.json
```

## View CORS

```bash
gcloud storage buckets describe "gs://$BUCKET_NAME" \
  --format="json(cors)"
```

## Remove CORS

Apply an empty array:

```json
[]
```

```bash
gcloud storage buckets update "gs://$BUCKET_NAME" \
  --cors-file=cors-empty.json
```

## Troubleshooting CORS

- Confirm the browser origin exactly matches.
- Confirm HTTP method is allowed.
- Confirm required response headers are exposed.
- Check browser developer tools.
- Confirm the request is not failing from IAM before CORS is evaluated.
- Do not use `*` casually for private applications.
- Remember that CORS is a browser security mechanism, not an IAM replacement.

---

# 24. Requester Pays

With Requester Pays enabled, the requester supplies a billing project for eligible request and network charges.

Use cases:

- Shared public datasets
- Partner data distribution
- Central data owner that should not pay every consumer's access costs

## Enable

```bash
gcloud storage buckets update "gs://$BUCKET_NAME" \
  --requester-pays
```

## Access with billing project

```bash
gcloud storage ls "gs://$BUCKET_NAME" \
  --billing-project="$PROJECT_ID"
```

## Disable

```bash
gcloud storage buckets update "gs://$BUCKET_NAME" \
  --no-requester-pays
```

The requester must have permission to use the specified billing project.

---

# 25. Website Hosting

Cloud Storage can host static content such as:

- HTML
- CSS
- JavaScript
- Images

It cannot execute server-side code such as:

- PHP
- Java
- Python
- Node.js server processes

## Configure website pages

```bash
gcloud storage buckets update "gs://$BUCKET_NAME" \
  --web-main-page-suffix=index.html \
  --web-error-page=404.html
```

## Upload site

```bash
gcloud storage rsync --recursive \
  ./website \
  "gs://$BUCKET_NAME"
```

## Public access

```bash
gcloud storage buckets add-iam-policy-binding "gs://$BUCKET_NAME" \
  --member="allUsers" \
  --role="roles/storage.objectViewer"
```

For HTTPS with a custom domain, a production design commonly uses an external Application Load Balancer and a backend bucket, potentially with Cloud CDN.

---

# 26. Data Transfer Options

## `gcloud storage cp`

Best for:

- Manual file copy
- Scripting
- Small-to-medium transfers
- Cloud Shell operations

## `gcloud storage rsync`

Best for:

- Directory synchronization
- Static website deployment
- Incremental mirroring
- Backup workflows

## Storage Transfer Service

Best for:

- Large scheduled transfers
- Bucket-to-bucket transfers
- Amazon S3 to Cloud Storage
- Azure or compatible sources
- Recurring migrations
- Managed transfer jobs

## Transfer Appliance

Best for:

- Very large offline data migration
- Limited network bandwidth
- Data center migration

## Cloud Storage FUSE

Mounts a bucket into a Linux file system interface.

Use with awareness that object storage semantics differ from POSIX file system semantics.

---

# 27. Notifications and Event-Driven Processing

Cloud Storage events can trigger downstream systems.

Common patterns:

```text
Cloud Storage → Eventarc → Cloud Run
Cloud Storage → Eventarc → Cloud Functions
Cloud Storage → Pub/Sub → Subscriber
```

Example use cases:

- Process uploaded images
- Extract document text
- Start data pipelines
- Scan uploaded files
- Generate thumbnails
- Send notifications

Typical events:

- Object finalized
- Object deleted
- Object archived
- Object metadata updated

Design idempotent event consumers because event delivery may be retried.

---

# 28. Logging, Monitoring, and Audit

## Cloud Audit Logs

Cloud Storage activities can appear in:

- Admin Activity logs
- Data Access logs
- System Event logs
- Policy Denied logs

## Useful monitoring signals

- Total bytes stored
- Object count
- Request count
- Error count
- Network egress
- Latency
- 4xx and 5xx responses

## Production recommendations

- Enable required Data Access logs.
- Create log-based alerts for denied access.
- Monitor unexpected public policy changes.
- Monitor deletion spikes.
- Monitor sudden egress growth.
- Export audit logs for long-term security analytics.
- Use labels and naming standards.
- Review IAM with Policy Analyzer and IAM Recommender where applicable.

---

# 29. Performance and Reliability

## Strong consistency

Cloud Storage provides strong consistency for object operations and listings.

After a successful write, subsequent reads and listings reflect the change.

## Parallelism

For high throughput:

- Upload multiple objects in parallel.
- Use resumable uploads for large objects.
- Use managed transfer services for very large migrations.
- Avoid serial transfer loops when parallel transfer is safe.
- Keep workloads near bucket location.

## Resumable uploads

Use resumable uploads for large or unreliable network transfers.

Benefits:

- Resume after interruption
- Avoid restarting entire upload
- Better reliability

## Preconditions

Use generation-match preconditions to avoid race conditions.

Concept:

```text
Write only if current generation equals X
```

or:

```text
Create only if no live object exists
```

This is important for concurrent pipelines.

## Idempotency

Data pipelines should:

- Use deterministic object names
- Use generation preconditions
- Handle retries safely
- Avoid duplicate processing
- Store processing state externally when needed

---

# 30. Common IAM Roles

| Role | Typical capability |
|---|---|
| `roles/storage.objectViewer` | Read and list objects |
| `roles/storage.objectCreator` | Create objects but not overwrite or delete |
| `roles/storage.objectUser` | Read, create, update, and delete objects for typical object workflows |
| `roles/storage.objectAdmin` | Full control of objects |
| `roles/storage.admin` | Full control of buckets and objects |
| `roles/storage.legacyBucketReader` | Legacy bucket access; avoid for new design |
| `roles/storage.legacyObjectReader` | Legacy object access; avoid for new design |

## Recommended examples

Upload-only pipeline:

```text
roles/storage.objectCreator
```

Read-only analytics service:

```text
roles/storage.objectViewer
```

Application managing its own object set:

```text
roles/storage.objectUser
```

Storage administrator:

```text
roles/storage.admin
```

Do not grant `roles/storage.admin` just to upload a file.

---

# 31. Terraform Example

## `main.tf`

```hcl
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_storage_bucket" "gcs_lab" {
  name                        = var.bucket_name
  location                    = var.region
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  force_destroy               = false

  labels = {
    environment = "dev"
    managed_by  = "terraform"
  }

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = 30
    }

    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }

  lifecycle_rule {
    condition {
      age = 365
    }

    action {
      type = "Delete"
    }
  }
}

resource "google_storage_bucket_object" "sample" {
  name         = "samples/hello.txt"
  bucket       = google_storage_bucket.gcs_lab.name
  content      = "Hello from Terraform"
  content_type = "text/plain"
}
```

## `variables.tf`

```hcl
variable "project_id" {
  type        = string
  description = "Google Cloud project ID"
}

variable "region" {
  type        = string
  description = "Bucket region"
  default     = "asia-south1"
}

variable "bucket_name" {
  type        = string
  description = "Globally unique Cloud Storage bucket name"
}
```

## `terraform.tfvars`

```hcl
project_id  = "your-project-id"
region      = "asia-south1"
bucket_name = "your-unique-bucket-name"
```

## Execute

```bash
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```

Cleanup:

```bash
terraform destroy
```

---

# 32. Complete GUI Lab

## Objective

Create a secure bucket, upload objects, configure IAM, enable versioning, and apply a lifecycle rule.

## Part A: Create bucket

1. Open Google Cloud Console.
2. Select the required project.
3. Navigate to **Cloud Storage → Buckets**.
4. Click **Create**.
5. Enter a globally unique name.
6. Select:
   - Location type: Region
   - Region: `asia-south1`
   - Storage class: Standard
7. Enable uniform bucket-level access.
8. Enforce public access prevention.
9. Keep or intentionally configure soft delete.
10. Click **Create**.

## Part B: Upload objects

1. Open the bucket.
2. Select the **Objects** tab.
3. Click **Upload files**.
4. Upload:
   - `hello.txt`
   - `sample.json`
5. Create a folder named `archive`.
6. Upload another file inside `archive`.

## Part C: Review metadata

1. Click an object.
2. Review:
   - Size
   - Content type
   - Storage class
   - Creation time
   - Update time
   - Generation
   - Public URL
   - Authenticated URL
3. Edit metadata if required.

## Part D: Configure IAM

1. Open the bucket's **Permissions** tab.
2. Click **Grant access**.
3. Add a user or service account.
4. Assign **Storage Object Viewer**.
5. Save.
6. Verify that public access remains blocked.

## Part E: Enable versioning

1. Open the bucket configuration.
2. Enable Object Versioning.
3. Upload a new file named `config.txt`.
4. Change its content locally.
5. Upload it again with the same object name.
6. View object versions.

## Part F: Add lifecycle rule

1. Open the bucket's **Lifecycle** tab.
2. Click **Add a rule**.
3. Select action:
   - Delete object
4. Select condition:
   - Age = 30 days
5. Save.

## Part G: Cleanup

1. Delete test objects.
2. Delete noncurrent versions.
3. Remove IAM test access.
4. Delete the bucket.

---

# 33. Complete CLI Lab

## Objective

Create a secure GCS bucket and test common administration commands.

## Step 1: Variables

```bash
export PROJECT_ID="your-project-id"
export REGION="asia-south1"
export BUCKET_NAME="${PROJECT_ID}-gcs-cli-lab-$(date +%s)"
```

## Step 2: Configure project

```bash
gcloud config set project "$PROJECT_ID"
gcloud services enable storage.googleapis.com
```

## Step 3: Create files

```bash
mkdir -p gcs-cli-lab/logs
echo "hello gcs" > gcs-cli-lab/hello.txt
echo '{"level":"INFO","message":"application started"}' \
  > gcs-cli-lab/logs/app.json
```

## Step 4: Create secure bucket

```bash
gcloud storage buckets create "gs://$BUCKET_NAME" \
  --location="$REGION" \
  --default-storage-class=STANDARD \
  --uniform-bucket-level-access
```

```bash
gcloud storage buckets update "gs://$BUCKET_NAME" \
  --public-access-prevention
```

## Step 5: Upload files

```bash
gcloud storage cp --recursive \
  gcs-cli-lab \
  "gs://$BUCKET_NAME/"
```

## Step 6: List files

```bash
gcloud storage ls --recursive "gs://$BUCKET_NAME/**"
```

## Step 7: Read object

```bash
gcloud storage cat \
  "gs://$BUCKET_NAME/gcs-cli-lab/hello.txt"
```

## Step 8: Download object

```bash
gcloud storage cp \
  "gs://$BUCKET_NAME/gcs-cli-lab/hello.txt" \
  ./hello-downloaded.txt
```

## Step 9: Enable versioning

```bash
gcloud storage buckets update "gs://$BUCKET_NAME" \
  --versioning
```

```bash
echo "hello gcs version 2" > gcs-cli-lab/hello.txt

gcloud storage cp \
  gcs-cli-lab/hello.txt \
  "gs://$BUCKET_NAME/gcs-cli-lab/hello.txt"
```

```bash
gcloud storage ls --all-versions \
  "gs://$BUCKET_NAME/gcs-cli-lab/hello.txt"
```

## Step 10: Configure lifecycle

```bash
cat > lifecycle.json <<'EOF'
{
  "rule": [
    {
      "action": {
        "type": "SetStorageClass",
        "storageClass": "NEARLINE"
      },
      "condition": {
        "age": 30,
        "matchesStorageClass": ["STANDARD"]
      }
    },
    {
      "action": {
        "type": "Delete"
      },
      "condition": {
        "age": 365
      }
    },
    {
      "action": {
        "type": "Delete"
      },
      "condition": {
        "isLive": false,
        "daysSinceNoncurrentTime": 30
      }
    }
  ]
}
EOF
```

```bash
gcloud storage buckets update "gs://$BUCKET_NAME" \
  --lifecycle-file=lifecycle.json
```

## Step 11: Verify bucket

```bash
gcloud storage buckets describe "gs://$BUCKET_NAME" \
  --format="yaml(name,location,storageClass,iamConfiguration,versioning,lifecycle)"
```

## Step 12: Cleanup

```bash
gcloud storage rm --recursive "gs://$BUCKET_NAME"
```

---

# 34. Static Website Lab

## Create site

```bash
mkdir -p website
```

`website/index.html`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>GCS Website</title>
</head>
<body>
  <h1>Hello from Google Cloud Storage</h1>
  <p>This is a static website.</p>
</body>
</html>
```

`website/404.html`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Not Found</title>
</head>
<body>
  <h1>404 - Page not found</h1>
</body>
</html>
```

## Upload

```bash
gcloud storage rsync --recursive \
  ./website \
  "gs://$BUCKET_NAME"
```

## Set website configuration

```bash
gcloud storage buckets update "gs://$BUCKET_NAME" \
  --web-main-page-suffix=index.html \
  --web-error-page=404.html
```

## Allow public read

First ensure public access prevention is not enforced for this intentionally public lab.

```bash
gcloud storage buckets update "gs://$BUCKET_NAME" \
  --no-public-access-prevention
```

```bash
gcloud storage buckets add-iam-policy-binding "gs://$BUCKET_NAME" \
  --member="allUsers" \
  --role="roles/storage.objectViewer"
```

## Test object URL

```text
https://storage.googleapis.com/BUCKET_NAME/index.html
```

## Production note

For a custom domain, TLS, caching, and stronger website delivery, use:

```text
Cloud Storage backend bucket
        ↓
External Application Load Balancer
        ↓
Cloud CDN
        ↓
Custom domain and managed TLS certificate
```

---

# 35. Lifecycle and Versioning Lab

## Enable versioning

```bash
gcloud storage buckets update "gs://$BUCKET_NAME" \
  --versioning
```

## Create versions

```bash
echo "build=1" > build.properties
gcloud storage cp build.properties "gs://$BUCKET_NAME/config/build.properties"

echo "build=2" > build.properties
gcloud storage cp build.properties "gs://$BUCKET_NAME/config/build.properties"

echo "build=3" > build.properties
gcloud storage cp build.properties "gs://$BUCKET_NAME/config/build.properties"
```

## List versions

```bash
gcloud storage ls --all-versions \
  "gs://$BUCKET_NAME/config/build.properties"
```

## Apply noncurrent version cleanup

```bash
cat > version-lifecycle.json <<'EOF'
{
  "rule": [
    {
      "action": {
        "type": "Delete"
      },
      "condition": {
        "isLive": false,
        "numNewerVersions": 2
      }
    }
  ]
}
EOF
```

```bash
gcloud storage buckets update "gs://$BUCKET_NAME" \
  --lifecycle-file=version-lifecycle.json
```

---

# 36. Signed URL Lab

## Upload private file

```bash
mkdir -p private
echo "confidential lab report" > private/report.txt

gcloud storage cp \
  private/report.txt \
  "gs://$BUCKET_NAME/private/report.txt"
```

## Confirm bucket is private

```bash
gcloud storage buckets update "gs://$BUCKET_NAME" \
  --public-access-prevention
```

## Generate signed URL

```bash
gcloud storage sign-url \
  "gs://$BUCKET_NAME/private/report.txt" \
  --duration=10m
```

## Test

Open the generated URL before it expires.

## Security note

- Keep validity periods short.
- Do not log signed URLs unnecessarily.
- Do not send signed URLs to untrusted channels.
- Signed URLs are bearer credentials.

---

# 37. Troubleshooting

## Error: bucket name already exists

```text
409 Conflict
```

Cause:

- Bucket names are globally unique.

Fix:

```bash
export BUCKET_NAME="${PROJECT_ID}-gcs-$(date +%s)-$RANDOM"
```

## Error: 403 Forbidden

Possible causes:

- Missing IAM permission
- Wrong active account
- Wrong project
- Public access prevention
- Organization policy
- VPC Service Controls
- Requester Pays missing billing project
- Service account lacks object permission
- ACL conflict in a fine-grained bucket

Check account:

```bash
gcloud auth list
```

Check project:

```bash
gcloud config get-value project
```

Check IAM:

```bash
gcloud storage buckets get-iam-policy "gs://$BUCKET_NAME"
```

Describe access settings:

```bash
gcloud storage buckets describe "gs://$BUCKET_NAME" \
  --format="yaml(iamConfiguration)"
```

## Error: 404 Not Found

Possible causes:

- Wrong bucket name
- Wrong object path
- Object name case mismatch
- Object deleted
- Insufficient access sometimes intentionally presented as not found
- Wrong generation

List exact names:

```bash
gcloud storage ls --recursive "gs://$BUCKET_NAME/**"
```

## Error: cannot delete bucket

Possible causes:

- Bucket is not empty
- Noncurrent versions exist
- Soft-deleted data or protection behavior
- Retention policy prevents deletion
- Object hold exists
- Missing bucket delete permission

List versions:

```bash
gcloud storage ls --all-versions "gs://$BUCKET_NAME/**"
```

Inspect retention:

```bash
gcloud storage buckets describe "gs://$BUCKET_NAME" \
  --format=json
```

## Error: object cannot be overwritten or deleted

Possible causes:

- Retention policy
- Temporary hold
- Event-based hold
- Missing `storage.objects.delete`
- Generation precondition failed

Describe object:

```bash
gcloud storage objects describe \
  "gs://$BUCKET_NAME/path/file.txt" \
  --format=json
```

## Error: CORS still failing

Check:

- Exact origin
- HTTP method
- Request headers
- Response headers
- Preflight `OPTIONS`
- Browser cache
- IAM
- Signed URL validity

View CORS:

```bash
gcloud storage buckets describe "gs://$BUCKET_NAME" \
  --format="json(cors)"
```

## Error: lifecycle did not run immediately

Lifecycle processing is asynchronous.

Check:

- Object age
- Object storage class
- Prefix or suffix condition
- Live vs noncurrent state
- Object custom time
- Retention or holds
- Lifecycle JSON syntax

## Error: requester pays project required

Use:

```bash
gcloud storage ls "gs://REQUESTER_PAYS_BUCKET" \
  --billing-project="$PROJECT_ID"
```

## Error: authentication credentials not found

```bash
gcloud auth login
gcloud auth application-default login
```

For workloads, use an attached service account or Workload Identity rather than user credentials.

## Debug CLI requests

```bash
gcloud storage ls "gs://$BUCKET_NAME" \
  --verbosity=debug
```

---

# 38. ACE Exam Notes

## High-value facts

1. Cloud Storage is object storage.
2. Buckets contain objects.
3. Bucket names are globally unique.
4. A bucket location should generally align with the workload.
5. Standard is for frequently accessed data.
6. Nearline has a 30-day minimum storage duration.
7. Coldline has a 90-day minimum storage duration.
8. Archive has a 365-day minimum storage duration.
9. Uniform bucket-level access disables ACLs.
10. Public access prevention blocks `allUsers` and `allAuthenticatedUsers`.
11. `roles/storage.objectViewer` provides object read access.
12. `roles/storage.objectCreator` allows creating objects but not deleting or overwriting existing objects.
13. Object Versioning preserves noncurrent generations.
14. Lifecycle rules automate deletion and storage-class transition.
15. Retention policies prevent deletion for a configured period.
16. Locking a retention policy is irreversible.
17. Signed URLs provide temporary access.
18. Requester Pays shifts eligible access costs to the requester.
19. Cloud Storage encrypts data at rest by default.
20. CMEK uses keys in Cloud KMS.
21. Bucket location is not simply changed in place.
22. Storage Transfer Service is preferred for managed, recurring, large transfers.
23. Transfer Appliance is useful when network transfer is impractical.
24. Static websites can host client-side assets, not server-side code.
25. Eventarc or Pub/Sub can connect object events to processing services.
26. Object names can contain `/`, but flat namespace folders are prefixes.
27. Object Lifecycle Management is asynchronous.
28. Cloud Storage provides strong consistency.
29. Soft delete and Object Versioning solve related but different recovery problems.
30. Use `gcloud storage` as the modern CLI interface.

## Service selection

| Requirement | Recommended service |
|---|---|
| Store images and videos | Cloud Storage |
| VM boot disk | Persistent Disk / Hyperdisk |
| Shared POSIX file system | Filestore |
| Relational data | Cloud SQL / AlloyDB |
| Analytical warehouse | BigQuery |
| Global key-value database | Bigtable / Firestore, depending on workload |
| Long-term archive | Cloud Storage Archive |
| Large recurring bucket transfer | Storage Transfer Service |
| Offline migration | Transfer Appliance |

## Common exam scenarios

### Scenario: Monthly backup

Choose:

```text
Nearline
```

### Scenario: Quarterly disaster recovery copy

Choose:

```text
Coldline
```

### Scenario: Seven-year compliance archive

Choose:

```text
Archive + retention policy
```

### Scenario: Temporary external download

Choose:

```text
Signed URL
```

### Scenario: Upload-only service account

Choose:

```text
roles/storage.objectCreator
```

### Scenario: Simplify access and prevent object ACL mistakes

Choose:

```text
Uniform bucket-level access
```

### Scenario: Ensure bucket can never be public

Choose:

```text
Public access prevention
```

### Scenario: Automatically delete logs after 90 days

Choose:

```text
Object Lifecycle Management
```

### Scenario: Access pattern is unknown

Consider:

```text
Autoclass
```

---

# 39. Practice Questions

## Question 1

A company stores monthly backup files that are normally read once every month. Which class is the best initial choice?

A. Standard  
B. Nearline  
C. Coldline  
D. Archive

**Answer: B. Nearline**

Nearline is designed for infrequently accessed data that is expected to be accessed approximately monthly.

---

## Question 2

A service account must upload new objects but must not read, overwrite, or delete existing objects. Which role should you grant?

A. Storage Admin  
B. Storage Object Viewer  
C. Storage Object Creator  
D. Storage Object Admin

**Answer: C. Storage Object Creator**

---

## Question 3

You want to prevent accidental public access to a production bucket, even if someone adds `allUsers` to an IAM policy. What should you configure?

A. Object Versioning  
B. Requester Pays  
C. Public access prevention  
D. CORS

**Answer: C. Public access prevention**

---

## Question 4

A company must prevent deletion of compliance records for seven years. Which feature is most appropriate?

A. CORS  
B. Retention policy  
C. Signed URL  
D. Storage Transfer Service

**Answer: B. Retention policy**

The policy can be locked when legal and operational approval has been completed.

---

## Question 5

A private object must be downloadable by a customer for 15 minutes. What should you use?

A. Make the bucket public  
B. Grant project Owner  
C. Signed URL  
D. Disable uniform access

**Answer: C. Signed URL**

---

## Question 6

You enabled Object Versioning and now storage usage is increasing. What is the best long-term solution?

A. Disable billing  
B. Delete the bucket daily  
C. Add a lifecycle rule for noncurrent versions  
D. Make objects public

**Answer: C. Add a lifecycle rule for noncurrent versions**

---

## Question 7

You need to transfer 500 TB from an on-premises data center, but available network bandwidth is insufficient. Which service should you consider?

A. Cloud Shell  
B. Transfer Appliance  
C. Cloud SQL Auth Proxy  
D. Pub/Sub Lite

**Answer: B. Transfer Appliance**

---

## Question 8

A frontend at `https://app.example.com` must upload directly to Cloud Storage from a browser. IAM is correct, but the browser blocks the request. What must you configure?

A. CORS  
B. Coldline  
C. Object hold  
D. Retention lock

**Answer: A. CORS**

---

## Question 9

A bucket has uniform bucket-level access enabled. How should permissions be managed?

A. Object ACLs only  
B. Bucket ACLs only  
C. IAM policies  
D. Linux permissions

**Answer: C. IAM policies**

---

## Question 10

An application needs frequent access to active user-uploaded images. Which class should be used?

A. Standard  
B. Nearline  
C. Coldline  
D. Archive

**Answer: A. Standard**

---

# 40. Cleanup

## Remove local files

```bash
rm -rf \
  gcs-demo \
  gcs-cli-lab \
  downloaded-data \
  downloaded-hello.txt \
  hello-downloaded.txt \
  website \
  private \
  lifecycle.json \
  version-lifecycle.json \
  cors.json \
  cors-empty.json \
  part1.txt \
  part2.txt \
  config.txt \
  build.properties
```

## Delete bucket

```bash
gcloud storage rm --recursive "gs://$BUCKET_NAME"
```

## Verify deletion

```bash
gcloud storage buckets list \
  --filter="name:$BUCKET_NAME"
```

---

# `gsutil` Compatibility Cheat Sheet

`gcloud storage` is the preferred modern command surface. Existing scripts and older labs may still use `gsutil`.

| Task | `gcloud storage` | `gsutil` |
|---|---|---|
| List buckets | `gcloud storage buckets list` | `gsutil ls` |
| Create bucket | `gcloud storage buckets create gs://BUCKET --location=REGION` | `gsutil mb -l REGION gs://BUCKET` |
| List objects | `gcloud storage ls gs://BUCKET` | `gsutil ls gs://BUCKET` |
| Upload | `gcloud storage cp file gs://BUCKET/` | `gsutil cp file gs://BUCKET/` |
| Recursive upload | `gcloud storage cp --recursive dir gs://BUCKET/` | `gsutil -m cp -r dir gs://BUCKET/` |
| Download | `gcloud storage cp gs://BUCKET/file .` | `gsutil cp gs://BUCKET/file .` |
| Sync | `gcloud storage rsync --recursive dir gs://BUCKET` | `gsutil -m rsync -r dir gs://BUCKET` |
| Delete object | `gcloud storage rm gs://BUCKET/file` | `gsutil rm gs://BUCKET/file` |
| Delete recursively | `gcloud storage rm --recursive gs://BUCKET` | `gsutil -m rm -r gs://BUCKET` |
| View bucket metadata | `gcloud storage buckets describe gs://BUCKET` | `gsutil ls -L -b gs://BUCKET` |
| Enable versioning | `gcloud storage buckets update gs://BUCKET --versioning` | `gsutil versioning set on gs://BUCKET` |
| Apply lifecycle | `gcloud storage buckets update gs://BUCKET --lifecycle-file=lifecycle.json` | `gsutil lifecycle set lifecycle.json gs://BUCKET` |
| Apply CORS | `gcloud storage buckets update gs://BUCKET --cors-file=cors.json` | `gsutil cors set cors.json gs://BUCKET` |
| IAM policy | `gcloud storage buckets get-iam-policy gs://BUCKET` | `gsutil iam get gs://BUCKET` |

---

# Command Cheat Sheet

```bash
# Authenticate
gcloud auth login
gcloud auth application-default login

# Set project
gcloud config set project PROJECT_ID

# Enable API
gcloud services enable storage.googleapis.com

# Create bucket
gcloud storage buckets create gs://BUCKET_NAME \
  --location=asia-south1 \
  --default-storage-class=STANDARD \
  --uniform-bucket-level-access

# List buckets
gcloud storage buckets list

# Describe bucket
gcloud storage buckets describe gs://BUCKET_NAME

# Upload file
gcloud storage cp file.txt gs://BUCKET_NAME/

# Upload directory
gcloud storage cp --recursive directory gs://BUCKET_NAME/

# List objects
gcloud storage ls --recursive gs://BUCKET_NAME/**

# Download
gcloud storage cp gs://BUCKET_NAME/file.txt .

# Copy
gcloud storage cp gs://SOURCE_BUCKET/file gs://DESTINATION_BUCKET/file

# Move
gcloud storage mv gs://BUCKET/old gs://BUCKET/new

# Sync
gcloud storage rsync --recursive ./local gs://BUCKET/path

# Delete object
gcloud storage rm gs://BUCKET/file

# Enable versioning
gcloud storage buckets update gs://BUCKET --versioning

# Set lifecycle
gcloud storage buckets update gs://BUCKET \
  --lifecycle-file=lifecycle.json

# Enforce public access prevention
gcloud storage buckets update gs://BUCKET \
  --public-access-prevention

# Add IAM
gcloud storage buckets add-iam-policy-binding gs://BUCKET \
  --member=user:USER_EMAIL \
  --role=roles/storage.objectViewer

# Generate signed URL
gcloud storage sign-url gs://BUCKET/file --duration=15m

# Delete bucket and content
gcloud storage rm --recursive gs://BUCKET
```

---

# 41. Official Documentation

- Cloud Storage overview: https://cloud.google.com/storage/docs/introduction
- Create buckets: https://cloud.google.com/storage/docs/creating-buckets
- Upload objects: https://cloud.google.com/storage/docs/uploading-objects
- Download objects: https://cloud.google.com/storage/docs/downloading-objects
- Storage classes: https://cloud.google.com/storage/docs/storage-classes
- Object Lifecycle Management: https://cloud.google.com/storage/docs/lifecycle
- IAM: https://cloud.google.com/storage/docs/access-control/iam
- Uniform bucket-level access: https://cloud.google.com/storage/docs/uniform-bucket-level-access
- Public access prevention: https://cloud.google.com/storage/docs/public-access-prevention
- Signed URLs: https://cloud.google.com/storage/docs/access-control/signed-urls
- Object Versioning: https://cloud.google.com/storage/docs/object-versioning
- Retention policies: https://cloud.google.com/storage/docs/bucket-lock
- CORS: https://cloud.google.com/storage/docs/cross-origin
- Requester Pays: https://cloud.google.com/storage/docs/requester-pays
- Static website hosting: https://cloud.google.com/storage/docs/hosting-static-website
- `gcloud storage` reference: https://cloud.google.com/sdk/gcloud/reference/storage
- Storage Transfer Service: https://cloud.google.com/storage-transfer/docs
- Cloud Storage pricing: https://cloud.google.com/storage/pricing

---

## Final Production Checklist

```text
[ ] Globally unique, non-sensitive bucket name
[ ] Correct region or dual-region selected
[ ] Appropriate storage class or Autoclass
[ ] Uniform bucket-level access enabled
[ ] Public access prevention enforced
[ ] Least-privilege IAM applied
[ ] No unnecessary service account keys
[ ] Soft delete duration reviewed
[ ] Object Versioning enabled only when needed
[ ] Lifecycle rule cleans old versions and stale data
[ ] Retention policy reviewed before locking
[ ] CMEK configured if compliance requires it
[ ] CORS restricted to trusted origins
[ ] Audit logging and alerts configured
[ ] Data transfer and egress costs reviewed
[ ] Recovery and restore procedures tested
[ ] Bucket deletion protection understood
