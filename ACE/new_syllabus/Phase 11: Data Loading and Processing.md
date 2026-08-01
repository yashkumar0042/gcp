# Phase 11: Data Loading and Processing — GCP ACE Detailed Notes

This phase covers how data enters Google Cloud, how it is processed, how asynchronous jobs are monitored, and how services such as Cloud Storage, BigQuery, Pub/Sub, and Dataflow work together.

---

# 1. Data-loading architecture in Google Cloud

A typical Google Cloud data pipeline contains four stages:

```text
Data Source
    |
    v
Cloud Storage / Pub/Sub
    |
    v
BigQuery Load Job / Dataflow Job
    |
    v
BigQuery Table
    |
    v
SQL queries, dashboards, ML, reporting
```

## Common pipeline examples

### Batch pipeline

```text
Application exports CSV every night
        |
        v
Cloud Storage bucket
        |
        v
BigQuery load job
        |
        v
BigQuery table
```

Use this when data arrives periodically, such as:

- Daily sales reports
- Monthly employee records
- Server log archives
- Data warehouse ingestion
- Database exports

### Streaming pipeline

```text
Application events
        |
        v
Pub/Sub topic
        |
        v
Dataflow streaming job
        |
        v
BigQuery table
```

Use this when data must be processed continuously, such as:

- Website click events
- IoT sensor readings
- Application logs
- Payment events
- Order events
- Real-time fraud detection

BigQuery load operations are implemented as asynchronous jobs. Loading, exporting, querying, and copying data create BigQuery jobs whose progress and result can be inspected later. citeturn233038search30turn356036search0

---

# 2. Batch processing versus streaming processing

## Batch processing

Batch processing handles a finite collection of data.

Examples:

- Process yesterday’s transaction file
- Load a 10 GB CSV file
- Generate a monthly report
- Transform archived log files

```text
Input: Fixed amount of data
Start: Explicitly started
End: Job finishes
Latency: Minutes or hours
```

Typical GCP services:

- BigQuery load jobs
- Dataflow batch jobs
- Storage Transfer Service
- Cloud Storage
- Dataproc

## Streaming processing

Streaming processing handles continuously arriving data.

Examples:

- Process every order as soon as it is created
- Analyze user clicks in near real time
- Monitor IoT devices
- Detect fraud during payment processing

```text
Input: Continuous data
Start: Job is started once
End: Runs until stopped or cancelled
Latency: Seconds or milliseconds
```

Typical GCP services:

- Pub/Sub
- Dataflow streaming
- BigQuery
- Cloud Run
- Eventarc

Dataflow supports both batch and streaming pipelines using the Apache Beam programming model. citeturn233038search27

## ACE exam decision rule

| Requirement | Recommended approach |
|---|---|
| Load a CSV file once | BigQuery load job |
| Load files every night | Scheduled BigQuery transfer or scheduled pipeline |
| Process real-time messages | Pub/Sub + Dataflow |
| Move terabytes from AWS S3 | Storage Transfer Service |
| Move on-premises files to Cloud Storage | Storage Transfer Service with agents |
| Query Cloud Storage without loading | BigQuery external table |
| Complex batch transformations | Dataflow batch |
| Simple SQL transformations | BigQuery SQL |
| Continuously transform streaming data | Dataflow streaming |

---

# 3. Load data using the CLI

Google Cloud provides several command-line tools:

| Tool | Primary purpose |
|---|---|
| `gcloud` | General Google Cloud resource management |
| `gcloud storage` | Cloud Storage operations |
| `bq` | BigQuery operations |
| `gsutil` | Older Cloud Storage CLI; still encountered in existing scripts |
| `gcloud dataflow` | Dataflow job management |

The current Cloud Storage CLI uses commands such as `gcloud storage cp`, including recursive and parallel copying support. citeturn233038search10turn233038search11turn233038search16

## Initial CLI configuration

```bash
gcloud auth login
```

Set the active project:

```bash
gcloud config set project PROJECT_ID
```

Set a default region:

```bash
gcloud config set compute/region asia-south1
```

Check the configuration:

```bash
gcloud config list
```

Confirm the authenticated account:

```bash
gcloud auth list
```

Enable required APIs:

```bash
gcloud services enable \
  storage.googleapis.com \
  bigquery.googleapis.com \
  dataflow.googleapis.com \
  pubsub.googleapis.com \
  storagetransfer.googleapis.com
```

## Important distinction

```bash
gcloud storage cp
```

Copies data into or between Cloud Storage buckets.

```bash
bq load
```

Loads structured data into a BigQuery table.

These are separate operations.

```text
Local file
   |
   | gcloud storage cp
   v
Cloud Storage object
   |
   | bq load
   v
BigQuery table
```

---

# 4. Loading local data into Cloud Storage

## Upload one file

```bash
gcloud storage cp sales.csv gs://BUCKET_NAME/
```

Upload into a folder-like prefix:

```bash
gcloud storage cp sales.csv gs://BUCKET_NAME/input/
```

Cloud Storage uses object names rather than traditional filesystem directories. A name such as `input/sales.csv` normally represents an object whose name contains a slash.

## Upload multiple files

```bash
gcloud storage cp *.csv gs://BUCKET_NAME/input/
```

## Upload a directory recursively

```bash
gcloud storage cp ./data gs://BUCKET_NAME/input/ --recursive
```

## List objects

```bash
gcloud storage ls gs://BUCKET_NAME/
```

Recursive listing:

```bash
gcloud storage ls gs://BUCKET_NAME/** 
```

## Download a file

```bash
gcloud storage cp gs://BUCKET_NAME/input/sales.csv .
```

## Copy between buckets

```bash
gcloud storage cp \
  gs://SOURCE_BUCKET/input/sales.csv \
  gs://DESTINATION_BUCKET/archive/sales.csv
```

## Delete an object

```bash
gcloud storage rm gs://BUCKET_NAME/input/sales.csv
```

## Create a bucket

```bash
gcloud storage buckets create gs://BUCKET_NAME \
  --location=asia-south1 \
  --uniform-bucket-level-access
```

Bucket names must be globally unique.

---

# 5. Loading local data directly into BigQuery

You do not always need Cloud Storage as an intermediate layer. The `bq load` command can load a local file.

Example CSV:

```csv
order_id,customer_name,product,quantity,amount,order_date
1001,Amit,Laptop,1,65000.00,2026-07-01
1002,Neha,Keyboard,2,3000.00,2026-07-02
1003,Rahul,Monitor,1,18000.00,2026-07-02
```

## Create a dataset

```bash
bq --location=asia-south1 mk \
  --dataset \
  PROJECT_ID:ace_data
```

## Load using schema autodetection

```bash
bq load \
  --location=asia-south1 \
  --source_format=CSV \
  --autodetect \
  --skip_leading_rows=1 \
  ace_data.sales \
  ./sales.csv
```

## Load using an explicit schema

```bash
bq load \
  --location=asia-south1 \
  --source_format=CSV \
  --skip_leading_rows=1 \
  ace_data.sales \
  ./sales.csv \
  order_id:INTEGER,customer_name:STRING,product:STRING,quantity:INTEGER,amount:NUMERIC,order_date:DATE
```

## Why explicit schemas are better for production

Autodetection is convenient for labs, but an explicit schema provides:

- Predictable data types
- Protection from unexpected input
- Better deployment consistency
- Easier schema governance
- Fewer accidental type changes

For example, an ID such as `00123` may be interpreted as an integer and lose its leading zeros. Defining it as `STRING` avoids this problem.

---

# 6. Loading data from Cloud Storage into BigQuery

BigQuery supports batch loading from Cloud Storage in formats including:

- CSV
- Newline-delimited JSON
- Avro
- Parquet
- ORC
- Firestore exports
- Datastore exports

After loading, BigQuery converts the data into its native columnar storage format. CSV and JSON can be gzip-compressed, while leaving large files uncompressed can improve loading speed when bandwidth is not a constraint. citeturn233038search3turn233038search17

## Basic flow

```text
gs://ace-data-bucket/input/sales.csv
                  |
                  | BigQuery load job
                  v
PROJECT_ID.ace_data.sales
```

## CLI load using autodetection

```bash
bq load \
  --location=asia-south1 \
  --source_format=CSV \
  --autodetect \
  --skip_leading_rows=1 \
  ace_data.sales \
  gs://BUCKET_NAME/input/sales.csv
```

## CLI load using explicit schema

```bash
bq load \
  --location=asia-south1 \
  --source_format=CSV \
  --skip_leading_rows=1 \
  ace_data.sales \
  gs://BUCKET_NAME/input/sales.csv \
  order_id:INTEGER,customer_name:STRING,product:STRING,quantity:INTEGER,amount:NUMERIC,order_date:DATE
```

## Loading multiple files using a wildcard

```bash
bq load \
  --location=asia-south1 \
  --source_format=CSV \
  --autodetect \
  --skip_leading_rows=1 \
  ace_data.sales \
  "gs://BUCKET_NAME/input/sales-*.csv"
```

Example matching objects:

```text
sales-2026-07-01.csv
sales-2026-07-02.csv
sales-2026-07-03.csv
```

## Important shell practice

Put wildcard Cloud Storage URIs inside quotes:

```bash
"gs://BUCKET_NAME/input/*.csv"
```

This prevents the local shell from attempting to expand the wildcard.

---

# 7. Write dispositions during BigQuery loading

A write disposition defines what BigQuery should do when the destination table already exists.

## Append data

```bash
bq load \
  --noreplace \
  --source_format=CSV \
  --autodetect \
  --skip_leading_rows=1 \
  ace_data.sales \
  gs://BUCKET_NAME/input/new_sales.csv
```

Conceptually:

```text
Existing rows + New rows
```

The API equivalent is:

```text
WRITE_APPEND
```

## Replace the table

```bash
bq load \
  --replace \
  --source_format=CSV \
  --autodetect \
  --skip_leading_rows=1 \
  ace_data.sales \
  gs://BUCKET_NAME/input/full_sales.csv
```

Conceptually:

```text
Existing rows removed
New file becomes the table
```

The API equivalent is:

```text
WRITE_TRUNCATE
```

## Fail when the table contains data

API disposition:

```text
WRITE_EMPTY
```

This protects against accidentally overwriting or appending to an existing table.

## ACE exam decision

| Requirement | Disposition |
|---|---|
| Add a new daily file | `WRITE_APPEND` |
| Perform full table refresh | `WRITE_TRUNCATE` |
| Prevent accidental duplicate load | `WRITE_EMPTY` |

---

# 8. CSV loading options

CSV files frequently require additional settings.

## Skip header row

```bash
--skip_leading_rows=1
```

## Different delimiter

For pipe-separated data:

```bash
--field_delimiter="|"
```

Example:

```text
1001|Amit|Laptop|65000
```

Command:

```bash
bq load \
  --source_format=CSV \
  --field_delimiter="|" \
  --autodetect \
  ace_data.sales \
  gs://BUCKET_NAME/input/sales.txt
```

## Allow quoted newlines

```bash
--allow_quoted_newlines
```

Useful when a text field contains a line break inside quotes.

## Ignore extra columns

```bash
--ignore_unknown_values
```

Use carefully. It can prevent a job from failing, but may also hide source-data quality problems.

## Allow a limited number of bad records

```bash
--max_bad_records=5
```

This allows the load job to complete when up to five malformed rows are present.

For production financial or compliance data, it is usually safer to reject bad rows rather than silently ignore them.

---

# 9. Location compatibility

The Cloud Storage bucket and BigQuery dataset should use compatible locations.

Example:

```text
Cloud Storage bucket: asia-south1
BigQuery dataset:     asia-south1
```

Or:

```text
Cloud Storage bucket: ASIA multi-region
BigQuery dataset:     ASIA multi-region
```

A common load failure occurs when the dataset and bucket are in incompatible locations.

## Good design practice

Choose the data location before creating:

- The bucket
- The BigQuery dataset
- The Dataflow job
- Temporary Dataflow storage
- Staging buckets

Keeping resources in compatible locations:

- Simplifies architecture
- Reduces data movement
- Helps data-residency compliance
- Can reduce network cost
- Avoids job failures

---

# 10. Loading through the Google Cloud Console

## Upload a file to Cloud Storage

1. Open **Cloud Storage**.
2. Select **Buckets**.
3. Open the target bucket.
4. Click **Upload files**.
5. Select the CSV file.
6. Confirm that the object appears in the bucket.

The console also supports dragging files directly into a bucket. citeturn233038search1

## Load the file into BigQuery

1. Open **BigQuery**.
2. Expand the project.
3. Select the dataset.
4. Click **Create table**.
5. For **Create table from**, select **Google Cloud Storage**.
6. Enter the source path:

```text
gs://BUCKET_NAME/input/sales.csv
```

7. Select file format: **CSV**.
8. Enter the destination table name:

```text
sales
```

9. Under schema, select either:
   - **Auto detect**, or
   - Enter the schema manually.
10. In advanced options:
   - Set header rows to skip to `1`.
   - Select the write preference.
   - Configure bad-record tolerance if necessary.
11. Click **Create table**.
12. Open **Job history** to review the load job.

---

# 11. BigQuery jobs

A BigQuery job is an asynchronous operation managed by BigQuery.

## Main job types

### 1. Query job

Executes SQL.

```sql
SELECT *
FROM `PROJECT_ID.ace_data.sales`;
```

### 2. Load job

Loads data into BigQuery.

```text
Cloud Storage/local file → BigQuery table
```

### 3. Extract job

Exports BigQuery data.

```text
BigQuery table → Cloud Storage
```

### 4. Copy job

Copies a table.

```text
BigQuery table A → BigQuery table B
```

BigQuery automatically creates jobs for query, load, extract, and copy operations. These jobs can run asynchronously and be checked by status. citeturn356036search0turn356036search12

## Job states

| State | Meaning |
|---|---|
| `PENDING` | Waiting for execution |
| `RUNNING` | Currently executing |
| `DONE` | Execution has finished |

Important:

```text
DONE does not always mean success.
```

A job can be `DONE` and still contain an error result. Always inspect the error fields.

## List recent jobs

```bash
bq ls -j
```

List more results:

```bash
bq ls -j -n 20
```

List all users’ jobs when permitted:

```bash
bq ls -j --all
```

## View a job

```bash
bq show --job=true JOB_ID
```

Specify the location:

```bash
bq --location=asia-south1 show --job=true JOB_ID
```

View complete JSON details:

```bash
bq --location=asia-south1 show \
  --format=prettyjson \
  --job=true \
  JOB_ID
```

The job location is important. A job ID can be provided in short form or as a fully qualified ID containing project and location. citeturn356036search0

## Cancel a job

```bash
bq cancel --location=asia-south1 JOB_ID
```

Cancellation is a request. A job that is already finishing may complete before cancellation is applied.

## BigQuery console job history

In the BigQuery console:

```text
BigQuery → Explorer → Job history
```

Two common views are:

- **Personal history**: jobs submitted by you
- **Project history**: jobs submitted in the project, subject to permission

Job details can include:

- Job type
- State
- Creation time
- Start time
- End time
- Duration
- User
- Source
- Destination
- Bytes processed
- Bytes billed
- Errors
- Labels

---

# 12. Querying loaded data

## View all rows

```sql
SELECT *
FROM `PROJECT_ID.ace_data.sales`;
```

## Calculate total revenue

```sql
SELECT
  SUM(amount) AS total_revenue
FROM `PROJECT_ID.ace_data.sales`;
```

## Aggregate by product

```sql
SELECT
  product,
  SUM(quantity) AS units_sold,
  SUM(amount) AS total_revenue
FROM `PROJECT_ID.ace_data.sales`
GROUP BY product
ORDER BY total_revenue DESC;
```

## Aggregate by date

```sql
SELECT
  order_date,
  COUNT(*) AS order_count,
  SUM(amount) AS daily_revenue
FROM `PROJECT_ID.ace_data.sales`
GROUP BY order_date
ORDER BY order_date;
```

## Run query from CLI

```bash
bq query \
  --use_legacy_sql=false \
  --location=asia-south1 \
  '
  SELECT
    product,
    SUM(amount) AS total_revenue
  FROM `PROJECT_ID.ace_data.sales`
  GROUP BY product
  ORDER BY total_revenue DESC
  '
```

## Dry run before query execution

```bash
bq query \
  --use_legacy_sql=false \
  --dry_run \
  '
  SELECT *
  FROM `PROJECT_ID.ace_data.sales`
  '
```

A dry run validates the query and estimates bytes processed without executing it.

---

# 13. Storage Transfer Service

Storage Transfer Service is a managed service for moving large amounts of data between storage systems.

It supports transfers such as:

- Amazon S3 to Cloud Storage
- Azure Blob Storage to Cloud Storage
- Cloud Storage to Cloud Storage
- On-premises filesystem to Cloud Storage
- Cloud Storage to on-premises filesystem
- Public URL lists to Cloud Storage
- HDFS to Cloud Storage

These supported movement patterns are documented in the Storage Transfer Service overview. citeturn233038search4

## Do not confuse these services

| Service | Purpose |
|---|---|
| `gcloud storage cp` | Manual or scripted object copy |
| Storage Transfer Service | Managed, scheduled, large-scale transfer |
| BigQuery Data Transfer Service | Scheduled ingestion into BigQuery |
| Transfer Appliance | Physical appliance for very large offline migrations |
| Dataflow | Transform and process data |
| Database Migration Service | Migrate supported databases |

## Use cases

### Cloud-to-cloud migration

```text
Amazon S3
   |
   v
Storage Transfer Service
   |
   v
Cloud Storage
```

### Scheduled bucket synchronization

```text
Source bucket
   |
   | every day
   v
Destination bucket
```

### On-premises file migration

```text
On-premises NFS
   |
   | Transfer agents
   v
Storage Transfer Service
   |
   v
Cloud Storage
```

Filesystem transfers use agents running close to the source or destination. Agents are grouped into agent pools, and pools can also be used to control bandwidth. citeturn233038search5turn233038search13

## Transfer job components

A transfer job typically includes:

- Source
- Destination
- Schedule
- Filters
- Transfer options
- Overwrite behavior
- Deletion behavior
- Notification configuration

## Filters

You can restrict transferred objects by:

- Include prefixes
- Exclude prefixes
- Last modified time
- Creation time
- Object conditions

Example:

```text
Include: reports/2026/
Exclude: reports/2026/temp/
```

## Transfer options

Depending on the source and destination, you may configure actions such as:

- Overwrite destination objects
- Skip objects already present
- Delete source objects after transfer
- Delete destination objects absent from source
- Preserve metadata
- Set bandwidth limits

Be careful with delete options because they can turn a copy operation into a synchronization or move operation.

## Storage Transfer Service versus CLI

Use `gcloud storage cp` when:

- Moving a few files
- Running a simple lab
- Performing an ad hoc upload
- Copying from a developer workstation

Use Storage Transfer Service when:

- Moving millions of objects
- Scheduling recurring transfers
- Migrating data from AWS or Azure
- Moving on-premises file data
- Requiring retries and managed monitoring
- Controlling bandwidth
- Performing large-scale enterprise migration

## Console creation flow

1. Open **Storage Transfer Service**.
2. Click **Create a transfer job**.
3. Select the source type.
4. Configure source credentials or source bucket.
5. Select the destination Cloud Storage bucket.
6. Configure filters.
7. Select overwrite and deletion options.
8. Configure the schedule:
   - Run once
   - Daily
   - Weekly
   - Custom
9. Create the job.
10. Review transfer operations and errors.

Storage Transfer Service supports creating transfer jobs that can be started immediately or run according to a schedule. citeturn233038search18

---

# 14. Dataflow jobs

Dataflow is a fully managed data-processing service based on Apache Beam.

It can perform:

- Batch ETL
- Streaming ETL
- Data enrichment
- Aggregation
- Windowing
- Filtering
- Format conversion
- Real-time analytics
- Data validation
- Sensitive-data transformation
- Machine-learning preprocessing

## Dataflow architecture

```text
Source
  |
  v
Apache Beam transforms
  |
  v
Sink
```

Example batch pipeline:

```text
Cloud Storage CSV
    |
    v
Parse rows
    |
    v
Remove invalid records
    |
    v
Transform columns
    |
    v
BigQuery
```

Example streaming pipeline:

```text
Pub/Sub
    |
    v
Parse JSON
    |
    v
Validate message
    |
    v
Enrich data
    |
    v
Window/Aggregate
    |
    v
BigQuery
```

## Dataflow job types

### Batch Dataflow job

- Finite input
- Runs to completion
- Suitable for files and historical data
- Status eventually becomes successful or failed

### Streaming Dataflow job

- Continuous input
- Runs until stopped or cancelled
- Suitable for Pub/Sub events
- Requires monitoring for backlog and lag

## Ways to create Dataflow jobs

### 1. Apache Beam SDK

Write pipeline code in:

- Java
- Python
- Go

### 2. Google-provided templates

Ready-to-use templates for common pipelines.

Examples include:

- Pub/Sub to BigQuery
- Pub/Sub to Cloud Storage
- Cloud Storage to BigQuery
- Cloud Storage text to Pub/Sub
- JDBC to BigQuery

### 3. Flex Templates

A container-based template format that allows custom dependencies and runtime configuration.

## Dataflow template example

The exact parameters depend on the selected template. A general command looks like:

```bash
gcloud dataflow flex-template run JOB_NAME \
  --project=PROJECT_ID \
  --region=REGION \
  --template-file-gcs-location=gs://TEMPLATE_BUCKET/template.json \
  --parameters=inputSubscription=projects/PROJECT_ID/subscriptions/SUBSCRIPTION_NAME \
  --parameters=outputTableSpec=PROJECT_ID:DATASET.TABLE \
  --staging-location=gs://BUCKET_NAME/staging \
  --temp-location=gs://BUCKET_NAME/temp
```

## Job naming rule

Dataflow job names normally use lowercase letters, numbers, and hyphens.

Good:

```text
orders-streaming-job
```

Avoid:

```text
Orders_Streaming_Job
```

## Staging and temporary locations

Dataflow frequently requires Cloud Storage locations:

```text
gs://BUCKET_NAME/staging
gs://BUCKET_NAME/temp
```

The staging location contains pipeline packages and deployment artifacts.

The temporary location contains intermediate files used while executing the pipeline.

---

# 15. Reviewing Dataflow job status

## List jobs

```bash
gcloud dataflow jobs list \
  --region=asia-south1
```

List active jobs:

```bash
gcloud dataflow jobs list \
  --region=asia-south1 \
  --status=active
```

## Describe a job

```bash
gcloud dataflow jobs describe JOB_ID \
  --region=asia-south1
```

## View logs

```bash
gcloud dataflow jobs show JOB_ID \
  --region=asia-south1
```

For detailed troubleshooting, use:

```text
Dataflow console → Job → Logs
```

or:

```text
Cloud Logging → Logs Explorer
```

## Dataflow states

Common states include:

| State | Meaning |
|---|---|
| `JOB_STATE_PENDING` | Waiting to start |
| `JOB_STATE_QUEUED` | Queued |
| `JOB_STATE_RUNNING` | Processing |
| `JOB_STATE_DONE` | Batch job completed successfully |
| `JOB_STATE_FAILED` | Job failed |
| `JOB_STATE_CANCELLED` | Job cancelled |
| `JOB_STATE_DRAINING` | Finishing buffered data before stopping |
| `JOB_STATE_DRAINED` | Drain completed |
| `JOB_STATE_UPDATED` | Replaced by an updated job |

## Cancel versus drain

### Cancel

Stops the job as soon as possible.

```text
New messages stop processing
Buffered messages may not complete
```

Use when:

- The job is causing damage
- The configuration is incorrect
- Immediate shutdown is necessary

### Drain

Stops accepting new work but allows in-flight data to finish.

```text
Stop new processing
Complete buffered records
Shut down gracefully
```

Use when:

- Deploying an updated streaming pipeline
- Avoiding loss of currently buffered data
- Gracefully ending a streaming job

Example:

```bash
gcloud dataflow jobs drain JOB_ID \
  --region=asia-south1
```

Cancel:

```bash
gcloud dataflow jobs cancel JOB_ID \
  --region=asia-south1
```

---

# 16. Important Dataflow monitoring metrics

The Dataflow monitoring interface provides metrics for debugging failures, identifying performance problems, and optimizing pipelines. Cloud Monitoring can also be used for dashboards and alerts. citeturn233038search6turn233038search9

## Throughput

Number of elements processed per second.

Low throughput can indicate:

- Insufficient workers
- Slow destination
- Expensive transformation
- Worker errors
- Hot keys

## Backlog

Amount of unprocessed input data.

In a Pub/Sub pipeline:

```text
Publishing rate > Processing rate
             =
Backlog grows
```

## System lag

How far the streaming pipeline is behind real time.

Example:

```text
Current time:       10:30
Newest processed:   10:20
System lag:         10 minutes
```

High system lag can indicate:

- Pipeline cannot keep up
- Insufficient workers
- Slow external API
- BigQuery write problems
- Data skew
- Worker failures

## Worker CPU utilization

Consistently high CPU may mean:

- More workers are needed
- Transformation logic is expensive
- Data is unevenly distributed

Consistently low CPU with poor throughput may indicate:

- I/O bottleneck
- External dependency delay
- Sink throttling
- Excessive waiting

## Failed records

Check for:

- Invalid JSON
- Schema mismatch
- Missing required fields
- BigQuery permission errors
- Invalid timestamp values
- Oversized messages
- Transformation exceptions

## Autoscaling

Dataflow can adjust worker count based on demand.

Benefits:

- Handles traffic changes
- Reduces manual capacity planning
- Can lower idle-resource cost

However, autoscaling cannot correct poor pipeline design, hot keys, or a slow external system.

---

# 17. Pub/Sub event-driven data flow

Pub/Sub is an asynchronous messaging service.

## Core concepts

### Topic

A named resource to which publishers send messages.

```text
projects/PROJECT_ID/topics/order-events
```

### Publisher

An application or service that sends messages.

### Subscription

A resource that receives messages from a topic.

### Subscriber

A service or application that processes messages from a subscription.

## Architecture

```text
Publisher
   |
   v
Pub/Sub topic
   |
   +------------------+
   |                  |
   v                  v
Subscription A    Subscription B
   |                  |
   v                  v
Dataflow          Cloud Run
```

Each subscription receives its own copy of the topic’s messages.

## Example event

```json
{
  "order_id": "ORD-1001",
  "customer_id": "C-501",
  "amount": 2499.00,
  "status": "CREATED",
  "event_time": "2026-07-18T10:30:00Z"
}
```

## Pub/Sub message structure

A message can contain:

```text
data       = message payload
attributes = key-value metadata
message_id = Pub/Sub-generated identifier
publish_time
ordering_key
```

Example attributes:

```text
source=checkout-service
environment=production
event_type=order_created
```

---

# 18. Event-driven Pub/Sub to Dataflow to BigQuery

## Architecture

```text
Order service
     |
     | publish JSON event
     v
Pub/Sub topic
     |
     v
Pub/Sub subscription
     |
     v
Dataflow streaming job
     |
     | parse, validate, transform
     v
BigQuery table
```

## Processing steps

1. The application publishes an event.
2. Pub/Sub stores the message.
3. Dataflow pulls the message from the subscription.
4. Dataflow decodes the payload.
5. The pipeline validates mandatory fields.
6. Invalid records are sent to a dead-letter path.
7. Valid records are transformed.
8. Dataflow writes the result to BigQuery.
9. The message is acknowledged.
10. BigQuery data becomes available for analytics.

## Why use Pub/Sub?

Pub/Sub decouples the producer and consumer.

Without Pub/Sub:

```text
Application → Dataflow/BigQuery directly
```

If the destination fails, the application may also fail.

With Pub/Sub:

```text
Application → Pub/Sub → Consumer
```

The producer can continue publishing while the consumer temporarily slows down, subject to retention and quota limits.

## Why use Dataflow between Pub/Sub and BigQuery?

Dataflow is useful when you need to:

- Parse JSON
- Rename columns
- Convert timestamps
- Filter events
- Remove sensitive fields
- Enrich records
- Aggregate records
- Apply event-time windows
- Route invalid data
- Deduplicate events
- Perform complex transformations

For simple schema-compatible ingestion, a direct Pub/Sub-to-BigQuery subscription may be simpler. For transformation logic, Dataflow is normally the better fit.

---

# 19. Delivery semantics and duplicate handling

Distributed messaging systems can redeliver messages.

A subscriber may receive the same logical event more than once because:

- Acknowledgement was delayed
- The worker crashed after processing
- Network communication failed
- The message was retried

Therefore, consumers should be idempotent.

## Idempotency

Processing the same event multiple times should not create multiple final results.

Example event identifier:

```json
{
  "event_id": "evt-842958",
  "order_id": "ORD-1001"
}
```

## BigQuery deduplication example

```sql
CREATE OR REPLACE TABLE `PROJECT_ID.ace_data.orders_deduplicated` AS
SELECT *
FROM `PROJECT_ID.ace_data.orders_raw`
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY event_id
  ORDER BY publish_time DESC
) = 1;
```

The latest row for each `event_id` is retained.

---

# 20. Dead-letter handling

A malformed event should not block the entire pipeline.

## Recommended pattern

```text
Pub/Sub
   |
   v
Dataflow
   |
   +-------------------+
   |                   |
   v                   v
Valid records      Invalid records
   |                   |
   v                   v
BigQuery main      Dead-letter topic/table
```

Store useful diagnostic information with failed records:

- Original payload
- Error message
- Processing timestamp
- Source topic
- Message ID
- Pipeline version

Example dead-letter row:

```json
{
  "message_id": "123456789",
  "raw_payload": "{invalid-json",
  "error_reason": "JSON parsing failed",
  "failed_at": "2026-07-18T10:35:00Z"
}
```

This makes troubleshooting and replay easier.

---

# 21. Creating a simple Pub/Sub flow with CLI

## Create a topic

```bash
gcloud pubsub topics create order-events
```

## Create a subscription

```bash
gcloud pubsub subscriptions create order-events-sub \
  --topic=order-events \
  --ack-deadline=60
```

## Publish a message

```bash
gcloud pubsub topics publish order-events \
  --message='{"order_id":"ORD-1001","amount":2499.00,"status":"CREATED"}' \
  --attribute=source=checkout,event_type=order_created
```

## Pull a message

```bash
gcloud pubsub subscriptions pull order-events-sub \
  --limit=10 \
  --auto-ack
```

Example conceptual output:

```text
DATA
{"order_id":"ORD-1001","amount":2499.00,"status":"CREATED"}

ATTRIBUTES
event_type=order_created
source=checkout
```

## View topic

```bash
gcloud pubsub topics describe order-events
```

## View subscription

```bash
gcloud pubsub subscriptions describe order-events-sub
```

## Delete resources

```bash
gcloud pubsub subscriptions delete order-events-sub
gcloud pubsub topics delete order-events
```

---

# 22. IAM roles commonly needed

Use least privilege rather than granting broad roles such as Owner or Editor.

## Cloud Storage upload

Common roles:

```text
roles/storage.objectCreator
roles/storage.objectUser
roles/storage.admin
```

`storage.objectCreator` allows object creation but not general deletion or overwrite capabilities.

## BigQuery load and query

Common roles:

```text
roles/bigquery.jobUser
roles/bigquery.dataEditor
roles/bigquery.dataViewer
```

Typical combination for loading:

```text
Project: roles/bigquery.jobUser
Dataset: roles/bigquery.dataEditor
Source bucket: permission to read objects
```

## Dataflow worker

Common role:

```text
roles/dataflow.worker
```

The service account may additionally need:

- Pub/Sub subscriber access
- Cloud Storage object access
- BigQuery data editor access
- Logging access
- Monitoring access

## Pub/Sub

Common roles:

```text
roles/pubsub.publisher
roles/pubsub.subscriber
roles/pubsub.viewer
```

## Storage Transfer Service

The transfer service account needs access to:

- Read the source
- Write to the destination
- Delete objects if deletion options are enabled

## ACE exam rule

Give permissions to the identity that actually performs the work:

```text
Human user
Deployment service account
Dataflow worker service account
Storage Transfer service agent
Application runtime service account
```

Do not assume that granting permission to your own user automatically grants it to Dataflow or another managed service.

---

# 23. Common errors and troubleshooting

## Error: Access denied to Cloud Storage object

Example:

```text
Access Denied: Permission storage.objects.get denied
```

Check:

```bash
gcloud storage objects describe \
  gs://BUCKET_NAME/input/sales.csv
```

Verify:

- Correct service account
- Bucket IAM
- Object path
- Project
- Uniform bucket-level access

---

## Error: Dataset not found in location

Example:

```text
Dataset was not found in location US
```

Cause:

- Job was submitted in `US`
- Dataset exists in `asia-south1`

Fix:

```bash
bq --location=asia-south1 ...
```

---

## Error: Schema mismatch

Example:

```text
Could not parse 'abc' as INT64
```

Possible fixes:

- Correct the source file
- Change the destination schema
- Load into a staging table
- Use `STRING` temporarily
- Use `SAFE_CAST` during transformation

Example:

```sql
SELECT
  SAFE_CAST(quantity AS INT64) AS quantity
FROM `PROJECT_ID.ace_data.sales_staging`;
```

---

## Error: Too many bad records

Inspect:

- Header rows
- Delimiter
- Quoting
- Date format
- Numeric formatting
- Empty required fields
- Extra columns
- Embedded newlines

---

## Error: BigQuery table already exists

Choose the correct behavior:

- Append
- Replace
- Use a different table name
- Use a partition
- Fail safely

---

## Dataflow job is running but no data reaches BigQuery

Check:

1. Are messages reaching Pub/Sub?
2. Is the correct subscription configured?
3. Is the Dataflow job reading from that subscription?
4. Is backlog increasing?
5. Are parsing errors present?
6. Does the worker service account have BigQuery permissions?
7. Does the target table schema match?
8. Are failed records sent to a dead-letter output?
9. Are bucket, dataset, topic, and job regions compatible?
10. Is the destination table identifier correct?

---

## Pub/Sub backlog keeps growing

Possible causes:

- Insufficient Dataflow workers
- Slow transformations
- BigQuery write failures
- Hot keys
- External API bottleneck
- Worker exceptions
- Quota limitation
- Incorrect autoscaling settings

Review:

- Backlog bytes
- Oldest unacknowledged message age
- System lag
- Worker CPU
- Error logs
- Throughput

---

# 24. Production data-loading best practices

## Use a landing bucket

```text
gs://company-data-landing/raw/orders/2026/07/18/
```

Avoid placing all data in the bucket root.

## Organize by source and date

```text
gs://bucket/raw/sales/year=2026/month=07/day=18/
```

This improves:

- Discoverability
- Lifecycle management
- Replay
- Troubleshooting
- Access control

## Separate raw and processed data

```text
raw/
validated/
rejected/
archive/
```

## Use staging tables

```text
Cloud Storage
    |
    v
BigQuery staging table
    |
    | validate and transform
    v
BigQuery production table
```

Benefits:

- Prevents invalid data from entering the final table
- Supports deduplication
- Allows schema validation
- Makes replay easier

## Prefer columnar formats for analytics

For large analytical workloads, Parquet or Avro often provides advantages over CSV:

- Embedded schema
- Better compression
- Faster processing
- More reliable types
- Reduced parsing ambiguity

CSV is useful for interoperability and simple labs, but is less robust for production pipelines.

## Add audit columns

Useful fields include:

```text
source_file_name
ingestion_timestamp
batch_id
source_system
message_id
publish_time
pipeline_version
```

## Design for replay

A good pipeline allows a failed day or batch to be rerun safely.

Use:

- Immutable raw files
- Batch identifiers
- Event IDs
- Staging tables
- Idempotent writes
- Dead-letter storage
- Documented replay commands

## Monitor and alert

Create alerts for:

- Failed jobs
- Growing Pub/Sub backlog
- High streaming lag
- Dataflow worker failures
- BigQuery insert errors
- Transfer job failures
- Missing expected daily file
- Unusual row-count changes

---

# 25. Complete mini lab: CSV → Cloud Storage → BigQuery → Query

## Lab objective

You will:

1. Create a CSV file.
2. Create a Cloud Storage bucket.
3. Upload the CSV file.
4. Create a BigQuery dataset.
5. Load the file into a BigQuery table.
6. Review the load job.
7. Query the data.
8. Clean up resources.

---

## Lab architecture

```text
Local sales.csv
       |
       | gcloud storage cp
       v
Cloud Storage bucket
       |
       | BigQuery load job
       v
BigQuery dataset.sales
       |
       | SQL
       v
Query result
```

---

## Step 1: Set variables

Run in Cloud Shell:

```bash
export PROJECT_ID=$(gcloud config get-value project)
export REGION=asia-south1
export BUCKET_NAME="${PROJECT_ID}-ace-data-loading"
export DATASET_ID=ace_data_loading
export TABLE_ID=sales
```

Verify:

```bash
echo "Project: $PROJECT_ID"
echo "Region: $REGION"
echo "Bucket: $BUCKET_NAME"
echo "Dataset: $DATASET_ID"
echo "Table: $TABLE_ID"
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
order_id,customer_name,product,quantity,amount,order_date
1001,Amit,Laptop,1,65000.00,2026-07-01
1002,Neha,Keyboard,2,3000.00,2026-07-02
1003,Rahul,Monitor,1,18000.00,2026-07-02
1004,Priya,Mouse,3,2400.00,2026-07-03
1005,Arjun,Laptop,1,72000.00,2026-07-03
1006,Kavya,Monitor,2,36000.00,2026-07-04
EOF
```

Review the file:

```bash
cat sales.csv
```

Expected output:

```text
order_id,customer_name,product,quantity,amount,order_date
1001,Amit,Laptop,1,65000.00,2026-07-01
...
```

---

## Step 4: Create the bucket

```bash
gcloud storage buckets create "gs://${BUCKET_NAME}" \
  --project="${PROJECT_ID}" \
  --location="${REGION}" \
  --uniform-bucket-level-access
```

Verify:

```bash
gcloud storage buckets describe "gs://${BUCKET_NAME}"
```

---

## Step 5: Upload the CSV

```bash
gcloud storage cp \
  sales.csv \
  "gs://${BUCKET_NAME}/input/sales.csv"
```

Verify:

```bash
gcloud storage ls "gs://${BUCKET_NAME}/input/"
```

Expected object:

```text
gs://PROJECT_ID-ace-data-loading/input/sales.csv
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
bq show "${PROJECT_ID}:${DATASET_ID}"
```

---

## Step 7: Load the CSV using explicit schema

```bash
bq load \
  --project_id="${PROJECT_ID}" \
  --location="${REGION}" \
  --source_format=CSV \
  --skip_leading_rows=1 \
  "${DATASET_ID}.${TABLE_ID}" \
  "gs://${BUCKET_NAME}/input/sales.csv" \
  order_id:INTEGER,customer_name:STRING,product:STRING,quantity:INTEGER,amount:NUMERIC,order_date:DATE
```

The command submits a BigQuery load job.

---

## Step 8: Inspect the table

```bash
bq show \
  --schema \
  --format=prettyjson \
  "${PROJECT_ID}:${DATASET_ID}.${TABLE_ID}"
```

Preview the rows:

```bash
bq head \
  --max_rows=10 \
  "${PROJECT_ID}:${DATASET_ID}.${TABLE_ID}"
```

---

## Step 9: Review BigQuery job history

List recent jobs:

```bash
bq ls -j -n 10
```

Copy the load job ID, then inspect it:

```bash
bq --location="${REGION}" show \
  --job=true \
  JOB_ID
```

For full details:

```bash
bq --location="${REGION}" show \
  --format=prettyjson \
  --job=true \
  JOB_ID
```

Confirm:

```text
Job type: load
State: SUCCESS/DONE
Source: gs://.../input/sales.csv
Destination: ace_data_loading.sales
```

---

## Step 10: Query all records

```bash
bq query \
  --project_id="${PROJECT_ID}" \
  --location="${REGION}" \
  --use_legacy_sql=false \
  "
  SELECT *
  FROM \`${PROJECT_ID}.${DATASET_ID}.${TABLE_ID}\`
  ORDER BY order_id
  "
```

---

## Step 11: Query revenue by product

```bash
bq query \
  --project_id="${PROJECT_ID}" \
  --location="${REGION}" \
  --use_legacy_sql=false \
  "
  SELECT
    product,
    SUM(quantity) AS total_units,
    SUM(amount) AS total_revenue
  FROM \`${PROJECT_ID}.${DATASET_ID}.${TABLE_ID}\`
  GROUP BY product
  ORDER BY total_revenue DESC
  "
```

Expected conceptual output:

| product | total_units | total_revenue |
|---|---:|---:|
| Laptop | 2 | 137000 |
| Monitor | 3 | 54000 |
| Keyboard | 2 | 3000 |
| Mouse | 3 | 2400 |

---

## Step 12: Query daily sales

```bash
bq query \
  --project_id="${PROJECT_ID}" \
  --location="${REGION}" \
  --use_legacy_sql=false \
  "
  SELECT
    order_date,
    COUNT(*) AS orders,
    SUM(quantity) AS items,
    SUM(amount) AS revenue
  FROM \`${PROJECT_ID}.${DATASET_ID}.${TABLE_ID}\`
  GROUP BY order_date
  ORDER BY order_date
  "
```

---

## Step 13: Add another CSV file

```bash
cat > sales_day2.csv <<'EOF'
order_id,customer_name,product,quantity,amount,order_date
1007,Rohit,Keyboard,1,1500.00,2026-07-05
1008,Meena,Mouse,2,1600.00,2026-07-05
EOF
```

Upload it:

```bash
gcloud storage cp \
  sales_day2.csv \
  "gs://${BUCKET_NAME}/input/sales_day2.csv"
```

Append it:

```bash
bq load \
  --project_id="${PROJECT_ID}" \
  --location="${REGION}" \
  --source_format=CSV \
  --skip_leading_rows=1 \
  --noreplace \
  "${DATASET_ID}.${TABLE_ID}" \
  "gs://${BUCKET_NAME}/input/sales_day2.csv" \
  order_id:INTEGER,customer_name:STRING,product:STRING,quantity:INTEGER,amount:NUMERIC,order_date:DATE
```

Check the new count:

```bash
bq query \
  --project_id="${PROJECT_ID}" \
  --location="${REGION}" \
  --use_legacy_sql=false \
  "
  SELECT COUNT(*) AS total_rows
  FROM \`${PROJECT_ID}.${DATASET_ID}.${TABLE_ID}\`
  "
```

Expected:

```text
8
```

---

## Step 14: Perform the lab through GUI

### Cloud Storage

1. Go to **Cloud Storage → Buckets**.
2. Click **Create**.
3. Enter a globally unique bucket name.
4. Select `asia-south1`.
5. Enable uniform bucket-level access.
6. Create the bucket.
7. Open the bucket.
8. Create or use the `input` prefix.
9. Upload `sales.csv`.

### BigQuery

1. Open **BigQuery**.
2. Select the project.
3. Click the project’s three-dot menu.
4. Select **Create dataset**.
5. Dataset ID: `ace_data_loading`.
6. Location: `asia-south1`.
7. Create the dataset.
8. Select the dataset.
9. Click **Create table**.
10. Source: **Google Cloud Storage**.
11. Select:

```text
gs://BUCKET_NAME/input/sales.csv
```

12. File format: CSV.
13. Table name: `sales`.
14. Set header rows to skip: `1`.
15. Enter the schema manually or enable autodetect.
16. Click **Create table**.
17. Open the table’s **Preview** tab.
18. Run the SQL queries.
19. Open **Job history** and inspect the load and query jobs.

---

## Step 15: Clean up

Delete the BigQuery dataset and all tables:

```bash
bq rm \
  -r \
  -f \
  -d \
  "${PROJECT_ID}:${DATASET_ID}"
```

Delete the bucket and its objects:

```bash
gcloud storage rm \
  --recursive \
  "gs://${BUCKET_NAME}"
```

Delete local files:

```bash
rm -f sales.csv sales_day2.csv
```

---

# 26. Optional extension lab: Pub/Sub event flow

## Create resources

```bash
gcloud pubsub topics create sales-events
```

```bash
gcloud pubsub subscriptions create sales-events-sub \
  --topic=sales-events \
  --ack-deadline=60
```

## Publish sales events

```bash
gcloud pubsub topics publish sales-events \
  --message='{"order_id":2001,"product":"Laptop","amount":75000,"event_time":"2026-07-18T12:00:00Z"}'
```

```bash
gcloud pubsub topics publish sales-events \
  --message='{"order_id":2002,"product":"Monitor","amount":22000,"event_time":"2026-07-18T12:01:00Z"}'
```

## Pull and acknowledge

```bash
gcloud pubsub subscriptions pull sales-events-sub \
  --limit=10 \
  --auto-ack
```

This demonstrates the event-driven source side. A production pipeline could connect this subscription to a Dataflow streaming template and then write transformed rows into BigQuery.

---

# 27. ACE exam-focused scenarios

## Scenario 1

A company generates one CSV file every night and wants to analyze it in BigQuery the next morning.

**Answer:** Upload to Cloud Storage and use a BigQuery batch load job or scheduled transfer.

Do not choose Dataflow unless transformations require it.

---

## Scenario 2

A company needs to migrate 500 TB from Amazon S3 to Cloud Storage with automatic retries and scheduling.

**Answer:** Storage Transfer Service.

Do not use a developer laptop with `gcloud storage cp`.

---

## Scenario 3

An application generates thousands of order events every second. Events must be filtered and enriched before storing them in BigQuery.

**Answer:**

```text
Pub/Sub → Dataflow streaming → BigQuery
```

---

## Scenario 4

A BigQuery load operation has been submitted, and an administrator needs to inspect its current state and errors.

**Answer:**

```bash
bq --location=LOCATION show --job=true JOB_ID
```

Or use BigQuery **Job history**.

---

## Scenario 5

A streaming Dataflow job must be stopped without discarding currently buffered records.

**Answer:** Drain the job rather than cancel it.

---

## Scenario 6

A team needs to add a new daily file to an existing BigQuery table.

**Answer:** Use append behavior, equivalent to `WRITE_APPEND`.

---

## Scenario 7

A team reloads the complete customer table every day.

**Answer:** Use replacement behavior, equivalent to `WRITE_TRUNCATE`.

---

## Scenario 8

A Dataflow pipeline shows increasing Pub/Sub backlog and increasing system lag.

**Answer:** The consumer is processing more slowly than messages are arriving. Check worker capacity, autoscaling, hot keys, destination errors, and transformation bottlenecks.

---

# 28. Final revision summary

```text
gcloud storage cp
    = Copy files to or from Cloud Storage

bq load
    = Load files into BigQuery

BigQuery load job
    = Batch ingestion into a table

BigQuery job history
    = Review queries, loads, copies, and extracts

Storage Transfer Service
    = Managed large-scale storage migration or synchronization

Dataflow batch
    = Process finite datasets

Dataflow streaming
    = Continuously process incoming events

Pub/Sub
    = Decouple publishers and subscribers

Cancel Dataflow
    = Stop quickly

Drain Dataflow
    = Stop gracefully after processing buffered data

WRITE_APPEND
    = Add rows

WRITE_TRUNCATE
    = Replace existing data

WRITE_EMPTY
    = Fail if destination is not empty
```

The most important ACE architecture pattern for this phase is:

```text
Batch:
Cloud Storage → BigQuery load job → BigQuery

Streaming:
Application → Pub/Sub → Dataflow → BigQuery

Migration:
External/on-premises storage → Storage Transfer Service → Cloud Storage
```
