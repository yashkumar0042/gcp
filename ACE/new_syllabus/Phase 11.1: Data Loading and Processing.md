# Phase 11: Data Loading and Processing

## 1. Learning objectives

After completing this phase, you should be able to:

- Upload local files to Cloud Storage.
- Load data from Cloud Storage into BigQuery.
- Understand BigQuery load, query, extract, and copy jobs.
- Transfer large datasets using Storage Transfer Service.
- Understand batch and streaming Dataflow jobs.
- Review BigQuery, Dataflow, and Storage Transfer job status.
- Build a basic event-driven data pipeline using Pub/Sub.
- Select the correct data-loading service for a given scenario.

---

# 2. Data-loading architecture in Google Cloud

A common Google Cloud analytics pipeline looks like this:

```text
Source system
    |
    | CSV, JSON, Avro, Parquet, events
    v
Cloud Storage or Pub/Sub
    |
    | Batch load or streaming processing
    v
BigQuery / Cloud Storage / Database
    |
    v
Analytics, dashboards, reports, ML
```

There are two major data-loading patterns.

## Batch processing

Batch processing handles a collection of records together.

Examples:

- Uploading a daily sales CSV file.
- Loading monthly billing records into BigQuery.
- Copying 10 TB of data from Amazon S3 to Cloud Storage.
- Processing log files every night.

Typical services:

- Cloud Storage
- BigQuery load jobs
- Storage Transfer Service
- Dataflow batch pipelines

## Streaming processing

Streaming processing handles data continuously as it arrives.

Examples:

- Processing online purchases in real time.
- Receiving IoT sensor readings.
- Analyzing application events.
- Detecting fraudulent transactions.
- Processing clickstream data.

Typical services:

- Pub/Sub
- Dataflow streaming pipelines
- BigQuery subscriptions
- BigQuery streaming ingestion

---

# 3. Loading data using the Google Cloud CLI

Google Cloud provides multiple command-line tools.

| Tool | Primary purpose |
|---|---|
| `gcloud` | General Google Cloud resource management |
| `gcloud storage` | Cloud Storage bucket and object operations |
| `bq` | BigQuery datasets, tables, queries, and jobs |
| `gsutil` | Older Cloud Storage command-line tool |
| `kubectl` | Kubernetes operations |
| `terraform` | Infrastructure provisioning |

For new Cloud Storage workflows, prefer:

```bash
gcloud storage
```

instead of older `gsutil` commands.

---

## 3.1 Authenticate and configure the CLI

```bash
gcloud auth login
```

Set the project:

```bash
gcloud config set project PROJECT_ID
```

Set a default region:

```bash
gcloud config set compute/region us-central1
```

Check the current configuration:

```bash
gcloud config list
```

Check the authenticated account:

```bash
gcloud auth list
```

---

## 3.2 Enable required APIs

```bash
gcloud services enable \
    storage.googleapis.com \
    bigquery.googleapis.com \
    dataflow.googleapis.com \
    pubsub.googleapis.com \
    storagetransfer.googleapis.com
```

Verify enabled services:

```bash
gcloud services list --enabled
```

---

# 4. Uploading data to Cloud Storage

Cloud Storage is an object-storage service. Data is stored as objects inside buckets.

Typical objects include:

- CSV files
- JSON files
- Images
- Videos
- Backups
- Log files
- Parquet files
- Avro files

The basic hierarchy is:

```text
Project
  └── Bucket
        └── Object
```

Example:

```text
gs://ace-data-bucket/input/customers.csv
```

Here:

- `ace-data-bucket` is the bucket.
- `input/customers.csv` is the object name.
- `input/` appears like a directory but is part of the object name.

Google recommends `gcloud storage cp` for uploading files from a local system. citeturn245362search0turn245362search32

---

## 4.1 Create a bucket

Bucket names must be globally unique.

```bash
export PROJECT_ID=$(gcloud config get-value project)
export BUCKET_NAME="${PROJECT_ID}-ace-data"
export REGION="us-central1"
```

Create the bucket:

```bash
gcloud storage buckets create "gs://${BUCKET_NAME}" \
    --location="${REGION}" \
    --uniform-bucket-level-access
```

List buckets:

```bash
gcloud storage buckets list
```

Describe the bucket:

```bash
gcloud storage buckets describe "gs://${BUCKET_NAME}"
```

---

## 4.2 Upload a single file

```bash
gcloud storage cp customers.csv "gs://${BUCKET_NAME}/input/customers.csv"
```

Upload the file while retaining its original filename:

```bash
gcloud storage cp customers.csv "gs://${BUCKET_NAME}/input/"
```

---

## 4.3 Upload multiple files

```bash
gcloud storage cp *.csv "gs://${BUCKET_NAME}/input/"
```

---

## 4.4 Upload a directory recursively

```bash
gcloud storage cp ./data "gs://${BUCKET_NAME}/input/" --recursive
```

The `gcloud storage cp` command can perform parallel copies when uploading many files. citeturn245362search13

---

## 4.5 List uploaded objects

```bash
gcloud storage ls "gs://${BUCKET_NAME}/"
```

Recursive listing:

```bash
gcloud storage ls --recursive "gs://${BUCKET_NAME}/"
```

---

## 4.6 Download an object

```bash
gcloud storage cp \
    "gs://${BUCKET_NAME}/input/customers.csv" \
    ./downloaded-customers.csv
```

---

## 4.7 Copy an object between buckets

```bash
gcloud storage cp \
    "gs://SOURCE_BUCKET/input/customers.csv" \
    "gs://DESTINATION_BUCKET/archive/customers.csv"
```

For a few files, `gcloud storage cp` is appropriate. For large-scale, recurring, or cross-cloud transfers, Storage Transfer Service is normally the better choice.

---

# 5. Loading data from Cloud Storage into BigQuery

BigQuery is Google Cloud’s serverless analytical data warehouse.

A typical batch-loading workflow is:

```text
Local CSV
   |
   v
Cloud Storage bucket
   |
   v
BigQuery load job
   |
   v
BigQuery table
   |
   v
SQL query
```

BigQuery supports loading formats such as:

- CSV
- Newline-delimited JSON
- Avro
- Parquet
- ORC

BigQuery creates a **load job** when data is loaded from Cloud Storage or a local file. Batch load jobs are well suited to data that changes periodically and does not require continuous real-time updates. citeturn245362search20

---

## 5.1 Important location rule

The Cloud Storage bucket and BigQuery dataset must use compatible locations.

Example:

- Cloud Storage bucket: `us-central1`
- BigQuery dataset: `us-central1`

This combination is valid.

Another valid example:

- Cloud Storage bucket: `US`
- BigQuery dataset: `US`

An incompatible location can cause the load job to fail.

### ACE exam point

When a BigQuery load from Cloud Storage fails unexpectedly, check:

1. IAM permissions.
2. Bucket and dataset locations.
3. Source file format.
4. Schema definition.
5. Delimiter and header settings.
6. Invalid or malformed rows.

---

# 6. BigQuery datasets and tables

A BigQuery dataset is a logical container for:

- Tables
- Views
- Routines
- Models

Hierarchy:

```text
Project
  └── Dataset
        └── Table
```

Fully qualified table name:

```text
PROJECT_ID.DATASET_ID.TABLE_ID
```

Example:

```text
ace-project.sales_data.customers
```

---

## 6.1 Create a dataset using the CLI

```bash
export DATASET_ID="ace_training"
```

Create the dataset:

```bash
bq --location=us-central1 mk \
    --dataset \
    "${PROJECT_ID}:${DATASET_ID}"
```

List datasets:

```bash
bq ls
```

Describe the dataset:

```bash
bq show "${PROJECT_ID}:${DATASET_ID}"
```

---

## 6.2 Create a CSV file

Create a file named `customers.csv`:

```csv
customer_id,name,city,total_purchase
101,Aarav,Delhi,2500.50
102,Meera,Mumbai,4100.00
103,Rohan,Bengaluru,1850.75
104,Ananya,Faridabad,3200.25
105,Kabir,Pune,2750.00
```

---

# 7. Loading CSV data into BigQuery using the CLI

## 7.1 Load with an explicit schema

```bash
bq load \
    --location=us-central1 \
    --source_format=CSV \
    --skip_leading_rows=1 \
    "${PROJECT_ID}:${DATASET_ID}.customers" \
    "gs://${BUCKET_NAME}/input/customers.csv" \
    customer_id:INTEGER,name:STRING,city:STRING,total_purchase:NUMERIC
```

Explanation:

| Option | Meaning |
|---|---|
| `--location` | BigQuery job location |
| `--source_format=CSV` | Source is CSV |
| `--skip_leading_rows=1` | Ignore the CSV header |
| Dataset and table | Destination table |
| `gs://...` | Cloud Storage source |
| Schema | Column names and data types |

Loading from Cloud Storage requires permission to create and execute the BigQuery load job, write to the table, and read the source bucket. citeturn245362search4turn245362search15

---

## 7.2 Load using schema autodetection

```bash
bq load \
    --location=us-central1 \
    --source_format=CSV \
    --skip_leading_rows=1 \
    --autodetect \
    "${PROJECT_ID}:${DATASET_ID}.customers_auto" \
    "gs://${BUCKET_NAME}/input/customers.csv"
```

### Autodetect advantages

- Faster setup.
- Useful for exploration.
- No manual schema required.

### Autodetect disadvantages

- Data types may be inferred incorrectly.
- Numeric identifiers may be treated as integers instead of strings.
- Dates and timestamps may be misinterpreted.
- Production pipelines become less predictable.

### Recommended approach

Use autodetection for quick testing, but use an explicit schema for production workloads.

---

## 7.3 Replace an existing table

```bash
bq load \
    --replace \
    --location=us-central1 \
    --source_format=CSV \
    --skip_leading_rows=1 \
    "${PROJECT_ID}:${DATASET_ID}.customers" \
    "gs://${BUCKET_NAME}/input/customers.csv" \
    customer_id:INTEGER,name:STRING,city:STRING,total_purchase:NUMERIC
```

`--replace` overwrites the existing table.

Use it carefully because existing table data is replaced.

---

## 7.4 Append to an existing table

```bash
bq load \
    --location=us-central1 \
    --source_format=CSV \
    --skip_leading_rows=1 \
    "${PROJECT_ID}:${DATASET_ID}.customers" \
    "gs://${BUCKET_NAME}/input/new_customers.csv" \
    customer_id:INTEGER,name:STRING,city:STRING,total_purchase:NUMERIC
```

By default, compatible records are appended when the table already exists.

---

# 8. Querying the loaded data

Run a standard SQL query:

```bash
bq query \
    --location=us-central1 \
    --use_legacy_sql=false \
    "
    SELECT
      customer_id,
      name,
      city,
      total_purchase
    FROM \`${PROJECT_ID}.${DATASET_ID}.customers\`
    ORDER BY total_purchase DESC
    "
```

Calculate total sales by city:

```bash
bq query \
    --location=us-central1 \
    --use_legacy_sql=false \
    "
    SELECT
      city,
      COUNT(*) AS customer_count,
      SUM(total_purchase) AS total_sales
    FROM \`${PROJECT_ID}.${DATASET_ID}.customers\`
    GROUP BY city
    ORDER BY total_sales DESC
    "
```

Filter records:

```bash
bq query \
    --location=us-central1 \
    --use_legacy_sql=false \
    "
    SELECT *
    FROM \`${PROJECT_ID}.${DATASET_ID}.customers\`
    WHERE total_purchase > 2500
    "
```

---

# 9. External tables versus loaded tables

BigQuery can query some files directly from Cloud Storage without first loading them into native BigQuery storage. This is called an external table.

## Native BigQuery table

```text
Cloud Storage file
      |
      | Load job
      v
BigQuery-managed storage
```

Advantages:

- Better query performance.
- Full BigQuery functionality.
- Better optimization.
- Suitable for repeated analytics.

## External table

```text
BigQuery query
      |
      v
Cloud Storage file
```

Advantages:

- No data duplication.
- Faster initial setup.
- Useful for temporary or infrequently queried data.
- Useful when data must remain in Cloud Storage.

Disadvantages:

- Generally slower than native BigQuery tables.
- Some BigQuery functionality may be limited.
- Query performance depends on the source files.

BigQuery supports querying data stored outside native BigQuery storage through external data sources. citeturn245362search44

### ACE exam decision

Use a native BigQuery table when:

- Data is queried frequently.
- Performance matters.
- The dataset supports regular analytics.

Use an external table when:

- Data must remain in Cloud Storage.
- Data is queried occasionally.
- You want to avoid loading or duplicating data.

---

# 10. Storage Transfer Service

Storage Transfer Service is a managed service for moving large amounts of data into, out of, or between storage systems.

It supports common migration and replication scenarios such as:

- Amazon S3 to Cloud Storage.
- Azure Blob Storage to Cloud Storage.
- One Cloud Storage bucket to another.
- On-premises file systems to Cloud Storage.
- HTTP or HTTPS sources to Cloud Storage.
- Scheduled transfers.
- Event-driven transfers.

Google identifies migration, backup, replication, and analytics-pipeline ingestion as common Storage Transfer Service use cases. citeturn245362search5turn245362search16

---

## 10.1 Storage Transfer Service architecture

```text
Source
  |
  | Transfer job
  v
Storage Transfer Service
  |
  v
Cloud Storage destination
```

Example:

```text
Amazon S3
   |
   v
Storage Transfer Service
   |
   v
Cloud Storage
   |
   v
BigQuery
```

---

## 10.2 When to use Storage Transfer Service

Use it when:

- Moving millions of objects.
- Migrating large datasets.
- Copying data between cloud providers.
- Scheduling daily or weekly transfers.
- Synchronizing buckets.
- Transferring data from on-premises storage.
- Moving data while applying include or exclude filters.

Do not normally use it to upload one small local CSV file. For that scenario, use:

```bash
gcloud storage cp
```

---

## 10.3 Transfer agents and agent pools

Some transfers are agentless, while on-premises and file-system transfers commonly use transfer agents.

An **agent pool** is a collection of transfer agents that share configuration and can have common bandwidth controls. citeturn245362search6

Conceptual flow:

```text
On-premises file system
        |
        v
Transfer agents
        |
        v
Agent pool
        |
        v
Storage Transfer Service
        |
        v
Cloud Storage
```

---

## 10.4 Scheduled transfers

A transfer job can run:

- Once.
- Daily.
- Weekly.
- On a recurring schedule.
- Based on an event-driven configuration.

Example:

```text
Every night at 1:00 AM:
Amazon S3 → Cloud Storage
```

Event-driven transfers can respond when objects are added or updated in supported sources, with Cloud Storage used as the destination. citeturn245362search39

---

## 10.5 Storage Transfer Service versus Transfer Appliance

| Requirement | Recommended service |
|---|---|
| Online transfer over a network | Storage Transfer Service |
| S3 or Azure to Cloud Storage | Storage Transfer Service |
| Scheduled bucket replication | Storage Transfer Service |
| Poor or unavailable internet | Transfer Appliance |
| Very large offline migration | Transfer Appliance |
| A few local files | `gcloud storage cp` |

---

# 11. BigQuery jobs

Many BigQuery operations run as jobs.

Main BigQuery job types:

| Job type | Purpose |
|---|---|
| Load job | Loads data into BigQuery |
| Query job | Executes SQL |
| Extract job | Exports BigQuery data |
| Copy job | Copies a table |
| Script job | Executes multi-statement SQL |

---

## 11.1 Load job

A load job imports data into a BigQuery table.

Example:

```text
Cloud Storage CSV → BigQuery table
```

CLI command:

```bash
bq load ...
```

---

## 11.2 Query job

A query job executes SQL.

```bash
bq query \
    --use_legacy_sql=false \
    "SELECT COUNT(*) FROM \`${PROJECT_ID}.${DATASET_ID}.customers\`"
```

---

## 11.3 Copy job

Copy a table:

```bash
bq cp \
    "${PROJECT_ID}:${DATASET_ID}.customers" \
    "${PROJECT_ID}:${DATASET_ID}.customers_backup"
```

Copy and overwrite the destination:

```bash
bq cp -f \
    "${PROJECT_ID}:${DATASET_ID}.customers" \
    "${PROJECT_ID}:${DATASET_ID}.customers_backup"
```

---

## 11.4 Extract job

Export a BigQuery table to Cloud Storage:

```bash
bq extract \
    --destination_format=CSV \
    "${PROJECT_ID}:${DATASET_ID}.customers" \
    "gs://${BUCKET_NAME}/exports/customers-*.csv"
```

BigQuery supports exporting table data to Cloud Storage in formats including CSV, JSON, Avro, and Parquet. citeturn245362search38

---

# 12. Reviewing BigQuery job status

## Using the Google Cloud console

1. Open **BigQuery Studio**.
2. Select **Job history**.
3. Choose:
   - Personal history
   - Project history
4. Select a job.
5. Review:
   - Job ID
   - Job type
   - Creation time
   - Start and end time
   - Status
   - Bytes processed
   - Errors
   - Destination table
   - User who started the job

## Using the CLI

List recent jobs:

```bash
bq ls -j
```

List more jobs:

```bash
bq ls -j -n 20
```

View job details:

```bash
bq show -j --format=prettyjson JOB_ID
```

Useful fields include:

```text
status.state
status.errorResult
status.errors
statistics.creationTime
statistics.startTime
statistics.endTime
```

Possible job states:

- `PENDING`
- `RUNNING`
- `DONE`

Important:

`DONE` only means the job finished. Check `errorResult` to determine whether it succeeded or failed.

---

# 13. Dataflow overview

Dataflow is a fully managed service for executing Apache Beam pipelines.

It supports:

- Batch processing.
- Streaming processing.
- Data transformation.
- Data enrichment.
- Data filtering.
- Aggregation.
- Windowing.
- ETL and ELT pipelines.

Dataflow manages much of the underlying infrastructure, including:

- Worker provisioning.
- Autoscaling.
- Job execution.
- Worker replacement.
- Monitoring integration.

A standard streaming analytics architecture is:

```text
Applications or devices
         |
         v
      Pub/Sub
         |
         v
      Dataflow
  Filter / transform
         |
         v
      BigQuery
         |
         v
   Looker dashboard
```

Google’s Dataflow overview uses Pub/Sub as the ingestion layer, Dataflow as the processing layer, and BigQuery as the analytical destination. citeturn245362search29

---

# 14. Dataflow batch jobs

A batch job processes bounded data.

Bounded data has a defined beginning and end.

Examples:

- Files stored in Cloud Storage.
- A database export.
- Yesterday’s transaction data.
- A finite collection of log records.

Architecture:

```text
Cloud Storage files
        |
        v
Dataflow batch pipeline
        |
  Clean and transform
        |
        v
BigQuery
```

Example transformations:

- Remove invalid rows.
- Convert strings to timestamps.
- Add calculated fields.
- Mask sensitive data.
- Aggregate records.
- Join datasets.

---

# 15. Dataflow streaming jobs

A streaming job processes unbounded data.

Unbounded data continuously arrives and does not have a natural endpoint.

Examples:

- Pub/Sub messages.
- Sensor data.
- Application events.
- Financial transactions.
- Clickstream events.

Architecture:

```text
Application
    |
    v
Pub/Sub topic
    |
    v
Pub/Sub subscription
    |
    v
Dataflow streaming job
    |
    v
BigQuery
```

A streaming job normally remains in the `RUNNING` state until it is stopped or cancelled.

---

# 16. Dataflow templates

A Dataflow template is a reusable pipeline that can be launched without writing the complete pipeline code.

Common Google-provided templates include:

- Cloud Storage Text to BigQuery
- Pub/Sub Subscription to BigQuery
- Pub/Sub Topic to BigQuery
- BigQuery to Cloud Storage
- Cloud Storage to Cloud SQL
- Kafka to BigQuery

The Pub/Sub Subscription to BigQuery template reads JSON messages from a Pub/Sub subscription and writes them to BigQuery. citeturn245362search24

Templates are useful when:

- The pipeline follows a standard pattern.
- You do not want to maintain Apache Beam code.
- The source and destination are already supported.
- Only configuration parameters change.

---

# 17. Reviewing Dataflow job status

## Using the console

1. Open **Dataflow**.
2. Select **Jobs**.
3. Choose the region.
4. Select a job.
5. Review:
   - Job graph
   - Job status
   - Execution details
   - Worker count
   - Throughput
   - Data freshness
   - System lag
   - Element count
   - Worker logs
   - Errors

Common states include:

- Queued
- Running
- Done
- Failed
- Cancelled
- Drained
- Stopped
- Updated

---

## Using the CLI

List jobs:

```bash
gcloud dataflow jobs list \
    --region=us-central1
```

List active jobs:

```bash
gcloud dataflow jobs list \
    --region=us-central1 \
    --status=active
```

Describe a job:

```bash
gcloud dataflow jobs describe JOB_ID \
    --region=us-central1
```

Cancel a batch job:

```bash
gcloud dataflow jobs cancel JOB_ID \
    --region=us-central1
```

Drain a streaming job:

```bash
gcloud dataflow jobs drain JOB_ID \
    --region=us-central1
```

---

## 17.1 Cancel versus drain

### Cancel

- Stops the job quickly.
- In-flight records may not finish processing.
- Appropriate when immediate termination is required.

### Drain

- Stops accepting new data.
- Attempts to process buffered and in-flight data.
- Preferred for graceful termination of streaming jobs.

### ACE exam point

For a production streaming pipeline where pending messages should be processed before shutdown, choose **drain**, not cancel.

---

# 18. Pub/Sub event-driven data flow

Pub/Sub is an asynchronous messaging service.

It decouples message producers from message consumers.

Core components:

| Component | Purpose |
|---|---|
| Publisher | Sends messages |
| Topic | Receives messages |
| Subscription | Delivers topic messages |
| Subscriber | Processes messages |
| Acknowledgment | Confirms successful processing |

---

## 18.1 Pub/Sub architecture

```text
Publisher
    |
    v
  Topic
    |
    +------------------+
    |                  |
    v                  v
Subscription A     Subscription B
    |                  |
    v                  v
Dataflow           Cloud Run
```

Each subscription receives its own copy of messages published after the subscription is created, subject to retention and configuration.

---

## 18.2 Event-driven example

Consider an e-commerce application.

```text
Customer places an order
         |
         v
Application publishes message
         |
         v
Pub/Sub topic: orders
         |
         v
Dataflow pipeline
         |
  Validate and transform
         |
         v
BigQuery orders table
```

Example message:

```json
{
  "order_id": "ORD-1001",
  "customer_id": "C-501",
  "product": "Laptop",
  "quantity": 1,
  "amount": 72000,
  "event_time": "2026-08-01T12:30:00Z"
}
```

---

# 19. Direct Pub/Sub-to-BigQuery integration

There are two important approaches.

## Approach 1: BigQuery subscription

```text
Pub/Sub topic
      |
      v
BigQuery subscription
      |
      v
BigQuery table
```

A BigQuery subscription writes Pub/Sub messages directly to an existing BigQuery table without requiring a separate subscriber application. citeturn245362search9

Use it when:

- Minimal or no transformation is required.
- The message schema maps directly to the table.
- You want a simpler architecture.
- You do not need complex processing.

## Approach 2: Pub/Sub and Dataflow

```text
Pub/Sub
   |
   v
Dataflow
   |
 Transform, filter, enrich
   |
   v
BigQuery
```

Use it when:

- Messages require transformation.
- Invalid records must be separated.
- Data must be enriched.
- Windowing or aggregation is required.
- Multiple destinations are needed.
- Complex error handling is required.

Google documents Dataflow templates that process JSON messages from Pub/Sub and write them to BigQuery. citeturn245362search18turn245362search30

---

# 20. Service-selection guide

| Scenario | Recommended service |
|---|---|
| Upload one local CSV | `gcloud storage cp` |
| Upload files through the console | Cloud Storage console |
| Load CSV from Cloud Storage to BigQuery | BigQuery load job |
| Query Cloud Storage data without loading | BigQuery external table |
| Copy millions of objects between buckets | Storage Transfer Service |
| Transfer S3 data to Cloud Storage | Storage Transfer Service |
| Move petabytes with poor connectivity | Transfer Appliance |
| Transform stored files before loading | Dataflow batch |
| Process events continuously | Pub/Sub + Dataflow |
| Send Pub/Sub data directly to BigQuery | BigQuery subscription |
| Run SQL analytics | BigQuery query job |
| Export BigQuery table to Cloud Storage | BigQuery extract job |
| Gracefully stop streaming processing | Drain Dataflow job |

---

# 21. Mini lab: CSV → Cloud Storage → BigQuery → SQL query

## Lab objective

You will:

1. Create a CSV file.
2. Create a Cloud Storage bucket.
3. Upload the CSV file.
4. Create a BigQuery dataset.
5. Load the CSV into a BigQuery table.
6. Run SQL queries.
7. Review the BigQuery job.
8. Clean up the resources.

---

# 22. Mini lab using the Google Cloud console

## Step 1: Create the CSV file

Create `sales.csv` locally:

```csv
order_id,customer_name,city,product,quantity,amount
1001,Aarav,Delhi,Keyboard,2,4000
1002,Meera,Mumbai,Monitor,1,18000
1003,Rohan,Bengaluru,Mouse,3,4500
1004,Ananya,Faridabad,Laptop,1,72000
1005,Kabir,Pune,Headphones,2,8000
1006,Ishita,Delhi,Monitor,2,36000
```

---

## Step 2: Create a Cloud Storage bucket

1. Open the Google Cloud console.
2. Go to **Cloud Storage → Buckets**.
3. Click **Create**.
4. Enter a globally unique bucket name.
5. Select a region, for example:
   - `us-central1`
6. Select **Standard** storage class.
7. Enable **Uniform access control**.
8. Keep public access prevention enabled.
9. Click **Create**.

---

## Step 3: Upload the CSV file

1. Open the bucket.
2. Click **Upload files**.
3. Select `sales.csv`.
4. Wait for the upload to complete.
5. Confirm that the object appears in the bucket.

---

## Step 4: Create a BigQuery dataset

1. Open **BigQuery Studio**.
2. In the Explorer panel, find your project.
3. Click the three-dot menu next to the project.
4. Select **Create dataset**.
5. Enter:

```text
Dataset ID: ace_training
Location: us-central1
```

6. Click **Create dataset**.

The dataset location should be compatible with the Cloud Storage bucket location.

---

## Step 5: Create the table from Cloud Storage

1. Open the `ace_training` dataset.
2. Click **Create table**.
3. For **Create table from**, select:
   - Google Cloud Storage
4. Browse to:

```text
gs://YOUR_BUCKET_NAME/sales.csv
```

5. File format:
   - CSV
6. Destination table:
   - `sales`
7. Under Schema:
   - Select **Edit as text**
8. Enter:

```text
order_id:INTEGER,
customer_name:STRING,
city:STRING,
product:STRING,
quantity:INTEGER,
amount:NUMERIC
```

9. Under Advanced options:
   - Header rows to skip: `1`
10. Click **Create table**.

---

## Step 6: Preview the data

1. Open the `sales` table.
2. Select the **Preview** tab.
3. Verify the rows and columns.

---

## Step 7: Query the table

Run:

```sql
SELECT
  order_id,
  customer_name,
  product,
  amount
FROM `PROJECT_ID.ace_training.sales`
ORDER BY amount DESC;
```

Calculate sales by city:

```sql
SELECT
  city,
  COUNT(*) AS total_orders,
  SUM(quantity) AS total_items,
  SUM(amount) AS total_sales
FROM `PROJECT_ID.ace_training.sales`
GROUP BY city
ORDER BY total_sales DESC;
```

Find orders above ₹10,000:

```sql
SELECT *
FROM `PROJECT_ID.ace_training.sales`
WHERE amount > 10000
ORDER BY amount DESC;
```

---

## Step 8: Review job history

1. In BigQuery Studio, open **Job history**.
2. Locate the load job.
3. Review:
   - Job type
   - Status
   - Source URI
   - Destination table
   - Start time
   - End time
   - Errors
4. Open the query jobs and review bytes processed.

---

# 23. Mini lab using the CLI

## Step 1: Configure variables

```bash
export PROJECT_ID=$(gcloud config get-value project)
export REGION="us-central1"
export BUCKET_NAME="${PROJECT_ID}-ace-sales"
export DATASET_ID="ace_training"
export TABLE_ID="sales"
```

---

## Step 2: Enable APIs

```bash
gcloud services enable \
    storage.googleapis.com \
    bigquery.googleapis.com
```

---

## Step 3: Create the CSV file

```bash
cat > sales.csv <<'EOF'
order_id,customer_name,city,product,quantity,amount
1001,Aarav,Delhi,Keyboard,2,4000
1002,Meera,Mumbai,Monitor,1,18000
1003,Rohan,Bengaluru,Mouse,3,4500
1004,Ananya,Faridabad,Laptop,1,72000
1005,Kabir,Pune,Headphones,2,8000
1006,Ishita,Delhi,Monitor,2,36000
EOF
```

Check the file:

```bash
cat sales.csv
```

---

## Step 4: Create the bucket

```bash
gcloud storage buckets create "gs://${BUCKET_NAME}" \
    --location="${REGION}" \
    --uniform-bucket-level-access
```

---

## Step 5: Upload the file

```bash
gcloud storage cp sales.csv "gs://${BUCKET_NAME}/input/sales.csv"
```

Verify:

```bash
gcloud storage ls "gs://${BUCKET_NAME}/input/"
```

---

## Step 6: Create the BigQuery dataset

```bash
bq --location="${REGION}" mk \
    --dataset \
    "${PROJECT_ID}:${DATASET_ID}"
```

Verify:

```bash
bq ls
```

---

## Step 7: Load the CSV into BigQuery

```bash
bq load \
    --location="${REGION}" \
    --source_format=CSV \
    --skip_leading_rows=1 \
    "${PROJECT_ID}:${DATASET_ID}.${TABLE_ID}" \
    "gs://${BUCKET_NAME}/input/sales.csv" \
    order_id:INTEGER,customer_name:STRING,city:STRING,product:STRING,quantity:INTEGER,amount:NUMERIC
```

---

## Step 8: Verify the table

```bash
bq show \
    "${PROJECT_ID}:${DATASET_ID}.${TABLE_ID}"
```

Preview records:

```bash
bq head \
    "${PROJECT_ID}:${DATASET_ID}.${TABLE_ID}"
```

---

## Step 9: Run SQL queries

```bash
bq query \
    --location="${REGION}" \
    --use_legacy_sql=false \
    "
    SELECT
      city,
      COUNT(*) AS total_orders,
      SUM(quantity) AS total_items,
      SUM(amount) AS total_sales
    FROM \`${PROJECT_ID}.${DATASET_ID}.${TABLE_ID}\`
    GROUP BY city
    ORDER BY total_sales DESC
    "
```

Query high-value orders:

```bash
bq query \
    --location="${REGION}" \
    --use_legacy_sql=false \
    "
    SELECT
      order_id,
      customer_name,
      product,
      amount
    FROM \`${PROJECT_ID}.${DATASET_ID}.${TABLE_ID}\`
    WHERE amount > 10000
    ORDER BY amount DESC
    "
```

---

## Step 10: Review jobs

```bash
bq ls -j -n 10
```

Copy a job ID from the output:

```bash
bq show -j --format=prettyjson JOB_ID
```

---

# 24. Optional event-driven lab: Pub/Sub to BigQuery

## Architecture

```text
CLI publisher
     |
     v
Pub/Sub topic
     |
     v
BigQuery subscription
     |
     v
BigQuery table
```

This lab demonstrates direct delivery without Dataflow.

---

## Step 1: Create a BigQuery table

```bash
bq mk \
    --table \
    "${PROJECT_ID}:${DATASET_ID}.events" \
    event_id:STRING,event_type:STRING,message:STRING
```

---

## Step 2: Create a Pub/Sub topic

```bash
gcloud pubsub topics create ace-events
```

---

## Step 3: Grant the Pub/Sub service agent access

Get the project number:

```bash
export PROJECT_NUMBER=$(gcloud projects describe "${PROJECT_ID}" \
    --format="value(projectNumber)")
```

The Pub/Sub service agent is:

```text
service-PROJECT_NUMBER@gcp-sa-pubsub.iam.gserviceaccount.com
```

Grant BigQuery Data Editor:

```bash
gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
    --member="serviceAccount:service-${PROJECT_NUMBER}@gcp-sa-pubsub.iam.gserviceaccount.com" \
    --role="roles/bigquery.dataEditor"
```

Grant BigQuery Metadata Viewer:

```bash
gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
    --member="serviceAccount:service-${PROJECT_NUMBER}@gcp-sa-pubsub.iam.gserviceaccount.com" \
    --role="roles/bigquery.metadataViewer"
```

---

## Step 4: Create the BigQuery subscription

```bash
gcloud pubsub subscriptions create ace-events-bq-sub \
    --topic=ace-events \
    --bigquery-table="${PROJECT_ID}:${DATASET_ID}.events" \
    --use-table-schema
```

---

## Step 5: Publish a message

```bash
gcloud pubsub topics publish ace-events \
    --message='{"event_id":"E-1001","event_type":"LOGIN","message":"User logged in"}'
```

Publish another message:

```bash
gcloud pubsub topics publish ace-events \
    --message='{"event_id":"E-1002","event_type":"PURCHASE","message":"Order completed"}'
```

---

## Step 6: Query the table

After allowing time for delivery, run:

```bash
bq query \
    --use_legacy_sql=false \
    "
    SELECT *
    FROM \`${PROJECT_ID}.${DATASET_ID}.events\`
    ORDER BY event_id
    "
```

---

# 25. Troubleshooting guide

## Error: Access denied while loading from Cloud Storage

Check that the user or service account has permissions such as:

- BigQuery Job User
- BigQuery Data Editor
- Storage Object Viewer

Typical predefined roles:

```text
roles/bigquery.jobUser
roles/bigquery.dataEditor
roles/storage.objectViewer
```

---

## Error: Not found—dataset

Check:

- Project ID.
- Dataset ID.
- Current authenticated project.
- Dataset location.

```bash
bq ls
```

---

## Error: CSV table has too many columns

Possible causes:

- Incorrect delimiter.
- Commas inside unquoted strings.
- Schema has fewer columns than the file.
- Malformed CSV rows.

---

## Error: Could not parse value

Example:

```text
Could not parse 'ABC' as INT64
```

Cause:

A source value does not match the destination data type.

Solutions:

- Clean the source file.
- Change the schema.
- Load into a staging table with string columns.
- Transform the data with Dataflow or SQL.

---

## Error: Location mismatch

Cause:

The job, dataset, and source bucket use incompatible locations.

Solution:

- Recreate the dataset in a compatible location.
- Move or copy the source data.
- Explicitly specify the correct job location.

---

## Dataflow job has no output

Check:

- Pub/Sub subscription backlog.
- Worker service account permissions.
- Input topic or subscription name.
- BigQuery table schema.
- Dead-letter or error output.
- Worker logs.
- Region.
- Pipeline parameters.

---

# 26. ACE exam tips

1. **Small local upload**

   Use:

   ```bash
   gcloud storage cp
   ```

2. **Large cross-cloud transfer**

   Use Storage Transfer Service.

3. **Offline petabyte-scale migration**

   Use Transfer Appliance.

4. **Periodic CSV loading**

   Use a BigQuery batch load job.

5. **Direct query over files**

   Use a BigQuery external table.

6. **Complex event transformation**

   Use Pub/Sub with Dataflow.

7. **Direct Pub/Sub delivery with no transformation**

   Use a BigQuery subscription.

8. **Graceful streaming shutdown**

   Drain the Dataflow job.

9. **Immediate streaming shutdown**

   Cancel the Dataflow job.

10. **Production table schema**

    Prefer an explicit schema over autodetection.

11. **Load job failure**

    Check IAM, location compatibility, file format, and schema.

12. **BigQuery job says `DONE`**

    Also check `errorResult`; `DONE` does not necessarily mean successful.

---

# 27. Practice questions

## Question 1

A company generates one CSV file every night and stores it in Cloud Storage. The file must be available for SQL analytics the next morning. No transformation is required.

What should you use?

A. Pub/Sub  
B. BigQuery load job  
C. Dataflow streaming job  
D. Transfer Appliance  

**Answer: B — BigQuery load job**

The input is bounded, periodic, and ready to load without transformation.

---

## Question 2

You need to transfer 50 million objects from Amazon S3 to Cloud Storage every week.

What should you use?

A. `gcloud storage cp`  
B. BigQuery Data Transfer Service  
C. Storage Transfer Service  
D. Cloud Functions  

**Answer: C — Storage Transfer Service**

It is designed for large-scale, scheduled, cross-cloud object transfers.

---

## Question 3

Your application publishes transaction events to Pub/Sub. Each event must be validated, enriched, grouped into one-minute windows, and written to BigQuery.

What should you use?

A. BigQuery load job  
B. Pub/Sub BigQuery subscription only  
C. Pub/Sub and Dataflow  
D. Storage Transfer Service  

**Answer: C — Pub/Sub and Dataflow**

Dataflow is required because transformations, enrichment, and windowed aggregations are needed.

---

## Question 4

A Dataflow streaming job must be stopped, but all currently buffered messages should be processed first.

Which action should you take?

A. Delete  
B. Cancel  
C. Drain  
D. Pause  

**Answer: C — Drain**

Drain stops new processing while allowing in-flight data to complete.

---

## Question 5

An analyst needs to query a Parquet file in Cloud Storage occasionally. The data should remain in Cloud Storage and should not be duplicated.

What should you create?

A. Native BigQuery table  
B. BigQuery external table  
C. Cloud SQL table  
D. Dataflow streaming job  

**Answer: B — BigQuery external table**

External tables allow BigQuery to query data that remains outside native BigQuery storage.

---

# 28. Cleanup

Delete the BigQuery dataset and its contents:

```bash
bq rm -r -f -d "${PROJECT_ID}:${DATASET_ID}"
```

Delete all objects and the bucket:

```bash
gcloud storage rm --recursive "gs://${BUCKET_NAME}"
```

Delete the Pub/Sub subscription:

```bash
gcloud pubsub subscriptions delete ace-events-bq-sub
```

Delete the Pub/Sub topic:

```bash
gcloud pubsub topics delete ace-events
```

Verify cleanup:

```bash
bq ls
gcloud storage buckets list
gcloud pubsub topics list
gcloud pubsub subscriptions list
```

---

# 29. Final revision summary

```text
Local files
   |
   | gcloud storage cp
   v
Cloud Storage
   |
   | BigQuery load job
   v
BigQuery table
   |
   | Query job
   v
SQL analytics
```

For larger migrations:

```text
S3 / Azure / on-premises
          |
          v
Storage Transfer Service
          |
          v
Cloud Storage
```

For streaming processing:

```text
Application
    |
    v
Pub/Sub
    |
    v
Dataflow
    |
    v
BigQuery
```

Remember the central service-selection rule:

- **Move files:** Cloud Storage CLI or Storage Transfer Service.
- **Load analytical data:** BigQuery load jobs.
- **Transform batch or streaming data:** Dataflow.
- **Transport real-time events:** Pub/Sub.
- **Review execution:** BigQuery Job History, Dataflow Jobs, and Storage Transfer job details.
:::

This phase naturally prepares you for observability, automation, and production data-pipeline operations.
