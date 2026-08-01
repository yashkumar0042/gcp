
# Phase 10: Google Cloud Databases and Data Products  
## GCP Associate Cloud Engineer Study Notes

This phase covers operational databases, analytical databases, caching, messaging, and data-processing services. For the ACE exam, focus mainly on:

- Identifying the correct product for a workload
- Creating and configuring resources
- Connecting securely
- Running basic queries
- Understanding high availability, backups, recovery, IAM, networking, and cost
- Recognizing when a product is a database versus a messaging or processing service

---

# 1. Database categories in Google Cloud

Google Cloud data products can be divided into five broad groups.

| Category | Products | Typical purpose |
|---|---|---|
| Relational operational databases | Cloud SQL, AlloyDB, Spanner | Application transactions using schemas and SQL |
| NoSQL operational databases | Firestore, Bigtable | Flexible documents or high-volume key-based access |
| Analytical data warehouse | BigQuery | Large-scale analytics and reporting |
| In-memory databases | Memorystore | Caching, sessions, counters, low-latency data |
| Messaging and processing | Pub/Sub, Dataflow, Managed Kafka | Event ingestion, streaming, transformation |

A useful exam rule:

- **Application transaction:** Cloud SQL, AlloyDB, Spanner
- **Mobile/web document data:** Firestore
- **Huge time-series/key-value workload:** Bigtable
- **Analytics over terabytes or petabytes:** BigQuery
- **Caching:** Memorystore
- **Event messaging:** Pub/Sub or Managed Kafka
- **Data transformation:** Dataflow

---

# 2. Cloud SQL

## 2.1 What is Cloud SQL?

Cloud SQL is a fully managed relational database service supporting:

- MySQL
- PostgreSQL
- Microsoft SQL Server

Google manages operations such as database infrastructure, patching, backups, high availability, failover, monitoring, logging, import, and export. citeturn599404search19turn599404search32

## 2.2 Common use cases

Use Cloud SQL for:

- E-commerce applications
- Employee-management systems
- WordPress websites
- Inventory applications
- Banking applications with moderate scale
- Applications being migrated from an existing MySQL, PostgreSQL, or SQL Server database

## 2.3 Cloud SQL architecture

A Cloud SQL deployment contains:

1. **Cloud SQL instance**
   - The managed database server
   - Defines CPU, memory, storage, networking, availability, and database engine

2. **Database**
   - Logical database inside the instance

3. **Tables**
   - Store rows and columns

4. **Users**
   - Database-level users such as `appuser`

Example:

```text
Cloud SQL PostgreSQL instance
└── Database: companydb
    ├── Table: employees
    ├── Table: departments
    └── User: appuser
```

## 2.4 Cloud SQL connectivity

Cloud SQL supports:

### Public IP

The instance receives a publicly reachable IP address.

Connections should still be protected using:

- Authorized networks
- SSL/TLS
- IAM database authentication where supported
- Cloud SQL Auth Proxy or Cloud SQL connectors

### Private IP

The Cloud SQL instance receives an IP from a private services access range.

Use private IP when:

- Applications run inside a VPC
- The database should not be exposed publicly
- Cloud Run, GKE, or Compute Engine needs private connectivity
- Security requirements prohibit public internet access

### Cloud SQL Auth Proxy

The proxy:

- Uses IAM credentials
- Creates an encrypted connection
- Avoids manually managing SSL certificates
- Does not automatically provide network reachability

The user or service account still needs appropriate Cloud SQL IAM permissions.

## 2.5 High availability

A highly available Cloud SQL instance has:

- A primary instance in one zone
- A standby instance in another zone of the same region
- Synchronous replication between primary and standby
- Automatic failover when the primary becomes unavailable

Cloud SQL high availability protects against a zonal failure, but Cloud SQL HA remains regional. A full regional outage requires a separate disaster-recovery strategy, such as a cross-region read replica or restored backup. citeturn599404search0turn599404search11turn599404search45

### Exam distinction

- **Zonal availability:** Cloud SQL HA
- **Read scaling:** Read replica
- **Cross-region disaster recovery:** Cross-region replica or backup restoration
- **HA standby:** Not normally used for application reads
- **Read replica:** Can be used for read-only queries

## 2.6 Backups and recovery

Cloud SQL supports:

- Automated backups
- On-demand backups
- Point-in-time recovery
- Export to Cloud Storage
- Restoration to a new or existing supported target, depending on operation

Cloud SQL backups are incremental and encrypted by default. citeturn599404search18

### Backup versus export

| Backup | Export |
|---|---|
| Used for database recovery | Used for portability or archival |
| Managed by Cloud SQL | Written to Cloud Storage |
| Faster operational recovery | Can be moved or inspected |
| Includes database backup state | Usually SQL dump or CSV |
| Best for restoring an instance | Best for migration or external processing |

### Point-in-time recovery

Point-in-time recovery uses:

- Automated backups
- Transaction logs or binary logs

It lets you recover the database to a time before:

- Accidental table deletion
- Incorrect update
- Application corruption
- User error

## 2.7 Cloud SQL storage

Cloud SQL storage includes:

- SSD or supported storage options
- Automatic storage increase
- Backup storage
- Transaction logs
- Replication traffic

Enable automatic storage increase for production databases to reduce the risk of the instance becoming unavailable because the disk is full.

## 2.8 Cloud SQL IAM roles

Common roles include:

| Role | Purpose |
|---|---|
| `roles/cloudsql.admin` | Full administrative access |
| `roles/cloudsql.editor` | Modify instances |
| `roles/cloudsql.viewer` | View instance information |
| `roles/cloudsql.client` | Connect through Cloud SQL Auth Proxy/connectors |
| `roles/cloudsql.instanceUser` | Log in using IAM database authentication |

Remember that **Google Cloud IAM and database permissions are separate**.

A principal may have permission to connect to an instance but still require a MySQL or PostgreSQL database user and table permissions.

## 2.9 Basic PostgreSQL queries

```sql
CREATE TABLE employees (
    employee_id SERIAL PRIMARY KEY,
    employee_name VARCHAR(100) NOT NULL,
    department VARCHAR(50),
    salary NUMERIC(10,2)
);

INSERT INTO employees (
    employee_name,
    department,
    salary
)
VALUES
    ('Amit', 'Engineering', 85000),
    ('Neha', 'Finance', 70000),
    ('Rahul', 'Engineering', 92000);

SELECT * FROM employees;

SELECT
    department,
    AVG(salary) AS average_salary
FROM employees
GROUP BY department;
```

## 2.10 When not to choose Cloud SQL

Do not choose Cloud SQL when:

- You need virtually unlimited horizontal relational scaling: use Spanner
- You need large analytical scans: use BigQuery
- You need document-oriented mobile data: use Firestore
- You need extremely high-volume key-based access: use Bigtable
- You need very high-performance PostgreSQL at enterprise scale: consider AlloyDB

---

# 3. Firestore

## 3.1 What is Firestore?

Firestore is a managed NoSQL document database for web, mobile, and server applications.

It stores data as:

```text
Collection
└── Document
    ├── Field
    ├── Field
    └── Subcollection
```

Firestore provides strongly consistent queries, transactions, atomic batch operations, automatic scaling, and regional or multi-region deployment options. citeturn735989search3turn735989search14

## 3.2 Firestore data model

Example:

```text
Collection: users
└── Document: user-101
    ├── name: "Tushar"
    ├── city: "Bangalore"
    ├── experience: 5
    └── Collection: orders
        └── Document: order-9001
```

Firestore does not store data in traditional relational tables.

Important terms:

- Collection
- Document
- Field
- Document ID
- Subcollection
- Index
- Query
- Transaction

## 3.3 Firestore modes

### Native mode

Best for:

- Mobile applications
- Web applications
- Firebase integration
- Real-time listeners
- Modern document database use cases

### Datastore mode

Best for:

- Applications using older Datastore APIs
- Datastore compatibility requirements

For most new applications, Firestore Native mode is the normal choice.

## 3.4 Firestore queries

Example using Python:

```python
from google.cloud import firestore

db = firestore.Client()

users_ref = db.collection("users")

users_ref.document("user-101").set({
    "name": "Tushar",
    "city": "Bangalore",
    "experience": 5
})

query = users_ref.where("city", "==", "Bangalore")

for document in query.stream():
    print(document.id, document.to_dict())
```

## 3.5 Firestore indexes

Firestore automatically creates many single-field indexes.

Composite indexes may be needed when:

- Filtering on multiple fields
- Combining filtering and sorting
- Running more complex queries

When an index is missing, Firestore commonly returns an error containing a link or instructions to create the required index.

## 3.6 Firestore multi-region deployment

Firestore can be deployed in:

- A regional location
- A multi-region location

Multi-region provides higher resilience and geographic replication, while regional placement can provide lower latency and potentially lower cost for region-local applications. citeturn735989search14turn735989search31

## 3.7 Firestore backup and restore

Firestore supports:

- Managed backups
- Backup schedules
- Export to Cloud Storage
- Import from Cloud Storage
- Point-in-time recovery where enabled and supported

For ACE questions, distinguish:

- Backup: operational recovery
- Export: portability, migration, or archival
- Multi-region replication: availability, not protection from logical deletion

Replication does not replace backups because accidental deletion may also be replicated.

## 3.8 Firestore cost model

Firestore cost is influenced by:

- Document reads
- Document writes
- Document deletes
- Stored data
- Index storage
- Network egress
- Backup/PITR storage

Exam trap:

A query that returns 1,000 documents generally results in document-read charges for the returned or scanned documents according to Firestore billing behavior. Poor data modeling can increase costs significantly.

## 3.9 When to choose Firestore

Choose Firestore for:

- Mobile applications
- Chat applications
- User profiles
- Product catalogs with flexible fields
- Real-time collaborative applications
- Serverless web backends

Avoid Firestore when:

- You need joins and complex relational SQL
- You need petabyte-scale analytics
- You need sequential time-series access at extremely high throughput
- You need traditional PostgreSQL compatibility

---

# 4. BigQuery

## 4.1 What is BigQuery?

BigQuery is Google Cloud’s serverless analytical data warehouse.

It separates:

- Storage
- Compute

It is designed for:

- Large analytical queries
- Reporting
- Business intelligence
- Machine learning with BigQuery ML
- Log analytics
- Data warehousing

BigQuery supports loading data from Cloud Storage in formats including CSV, JSON, Avro, Parquet, and ORC. citeturn599404search27turn599404search40

## 4.2 BigQuery hierarchy

```text
Project
└── Dataset
    ├── Table
    ├── View
    ├── Materialized view
    ├── Model
    └── Routine
```

### Project

Billing and IAM boundary.

### Dataset

A logical container for BigQuery objects. Datasets also establish location and access boundaries. citeturn599404search13

### Table

Stores rows in columnar format.

### View

Saved SQL query that does not normally store query results permanently.

### Materialized view

Stores precomputed results and refreshes them according to supported behavior.

## 4.3 BigQuery is OLAP, not OLTP

BigQuery is optimized for:

- Large scans
- Aggregations
- Reporting
- Historical analysis

It is not normally used as the transactional backend for:

- Login requests
- Shopping-cart updates
- Individual bank transactions
- High-frequency single-row updates

## 4.4 BigQuery query example

```sql
SELECT
  department,
  COUNT(*) AS employee_count,
  AVG(salary) AS average_salary
FROM `my-project.hr.employees`
GROUP BY department
ORDER BY average_salary DESC;
```

## 4.5 Partitioning

Partitioning divides a table into smaller sections.

Common partition types:

- Ingestion-time partitioning
- Date or timestamp column partitioning
- Integer-range partitioning

Example:

```sql
CREATE TABLE `my-project.sales.orders_partitioned`
PARTITION BY DATE(order_timestamp)
AS
SELECT *
FROM `my-project.sales.orders`;
```

Benefits:

- Reduces data scanned
- Improves performance
- Reduces query cost

Good query:

```sql
SELECT *
FROM `my-project.sales.orders_partitioned`
WHERE DATE(order_timestamp) = '2026-07-01';
```

Bad query:

```sql
SELECT *
FROM `my-project.sales.orders_partitioned`;
```

The second query scans all partitions unless filters or table configuration limit it.

## 4.6 Clustering

Clustering organizes data using selected columns.

Example:

```sql
CREATE TABLE `my-project.sales.orders_clustered`
PARTITION BY DATE(order_timestamp)
CLUSTER BY customer_id, region
AS
SELECT *
FROM `my-project.sales.orders`;
```

Use clustering when queries frequently filter by:

- Customer ID
- Region
- Product ID
- Status

## 4.7 BigQuery pricing models

Major cost components:

### Storage costs

Based on stored logical or physical data according to the configured model.

### Compute costs

Commonly:

- On-demand queries based on bytes processed
- Capacity-based compute using slots or reservations

### Other costs

- Streaming ingestion where applicable
- BigQuery Storage API
- Data transfer
- BI Engine
- BigQuery Omni or external processing where used

## 4.8 Cost-control techniques

- Use partition filters
- Avoid `SELECT *`
- Select only required columns
- Use clustered tables
- Preview data instead of querying entire tables
- Use dry runs
- Set maximum bytes billed
- Use materialized views for repeated aggregations
- Use long-term storage benefits where applicable
- Use batch loads instead of continuous ingestion when real-time data is unnecessary

Example dry run:

```bash
bq query \
  --use_legacy_sql=false \
  --dry_run \
  'SELECT department, AVG(salary)
   FROM `PROJECT_ID.hr.employees`
   GROUP BY department'
```

## 4.9 BigQuery backup and recovery concepts

BigQuery provides data-protection capabilities such as:

- Time travel
- Table snapshots
- Table clones
- Dataset copy
- Export to Cloud Storage

A typical accidental-deletion recovery can use time-travel syntax or a snapshot, subject to the configured retention period.

Example concept:

```sql
SELECT *
FROM `project.dataset.orders`
FOR SYSTEM_TIME AS OF
TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 1 HOUR);
```

## 4.10 Loading data from Cloud Storage

Example CSV file:

```csv
employee_id,employee_name,department,salary
1,Amit,Engineering,85000
2,Neha,Finance,70000
3,Rahul,Engineering,92000
```

CLI:

```bash
bq load \
  --source_format=CSV \
  --skip_leading_rows=1 \
  --autodetect \
  PROJECT_ID:ace_lab.employees \
  gs://BUCKET_NAME/employees.csv
```

BigQuery load jobs require BigQuery permissions and access to the source Cloud Storage object. citeturn599404search2turn599404search12

---

# 5. Spanner

## 5.1 What is Spanner?

Spanner is a fully managed, distributed relational database.

It provides:

- Relational schema
- SQL
- ACID transactions
- Strong consistency
- Horizontal scaling
- Regional, dual-region, and multi-region configurations
- High availability

Spanner synchronously replicates data using a Paxos-based replication design and supports strongly consistent operations across distributed replicas. citeturn599404search24turn599404search30

## 5.2 Use cases

Use Spanner for:

- Global financial platforms
- Global inventory systems
- Large gaming backends
- Telecom platforms
- Global order-processing systems
- Workloads that need SQL plus horizontal scaling

## 5.3 Spanner resource hierarchy

```text
Project
└── Spanner instance
    └── Database
        ├── Table
        ├── Index
        └── Change stream
```

### Instance

Defines:

- Compute capacity
- Region configuration
- Nodes or processing units

### Database

Contains schema, tables, indexes, and data.

## 5.4 Spanner versus Cloud SQL

| Requirement | Cloud SQL | Spanner |
|---|---|---|
| MySQL/PostgreSQL/SQL Server compatibility | Yes | No direct engine compatibility |
| Traditional regional application | Excellent | May be unnecessary |
| Horizontal relational scaling | Limited | Core capability |
| Multi-region relational database | Limited DR patterns | Native configurations |
| Strong consistency globally | Not its primary design | Yes |
| Lower small-workload cost | Usually better | Usually more expensive |
| Very large global workload | Limited | Designed for it |

## 5.5 Spanner multi-region

Spanner offers:

- Regional configurations
- Dual-region configurations
- Multi-region configurations

Multi-region configurations replicate data across zones and regions. They normally include multiple read-write and read-only replicas according to the chosen configuration. citeturn599404search29

## 5.6 Spanner SQL example

```sql
CREATE TABLE Customers (
    CustomerId STRING(36) NOT NULL,
    CustomerName STRING(100),
    City STRING(100)
) PRIMARY KEY (CustomerId);
```

Insert:

```sql
INSERT INTO Customers (
    CustomerId,
    CustomerName,
    City
)
VALUES (
    'customer-101',
    'Tushar',
    'Bangalore'
);
```

Query:

```sql
SELECT
    CustomerId,
    CustomerName,
    City
FROM Customers
WHERE City = 'Bangalore';
```

## 5.7 Spanner backup and restore

Spanner supports:

- Backups
- Backup schedules
- Incremental backups where supported/configured
- Point-in-time recovery
- Database restore
- Export through Dataflow

Spanner backups can be retained for extended periods, while PITR supports recovering recent database state according to the configured retention window. citeturn599404search15turn599404search35

Important:

A Spanner backup is restored to a **new database**, not over the existing database.

---

# 6. Bigtable

## 6.1 What is Bigtable?

Bigtable is a fully managed, wide-column NoSQL database designed for:

- Very high throughput
- Very low-latency key-based access
- Massive data volumes
- Time-series data
- IoT telemetry
- Financial market data
- Personalization
- Ad-tech data

Bigtable stores sparse tables, and missing columns in a row do not consume storage like populated cells. citeturn735989search0turn735989search21

## 6.2 Bigtable data model

```text
Table
└── Row key
    └── Column family
        └── Column qualifier
            └── Timestamped cell value
```

Example:

```text
Table: sensor_data

Row key: device-101#20260718
Column family: metrics
metrics:temperature = 32
metrics:humidity = 70
```

## 6.3 Row key importance

The row key determines:

- Data distribution
- Query efficiency
- Access pattern
- Hotspot risk

Bad row key for high write rates:

```text
20260718080001
20260718080002
20260718080003
```

This may direct sequential writes to a narrow key range.

Better approach:

```text
device-101#20260718080001
device-205#20260718080002
device-309#20260718080003
```

The exact design depends on access patterns.

## 6.4 Bigtable queries

Bigtable is not primarily queried using traditional relational joins.

Use:

- Client libraries
- `cbt` CLI
- Supported Bigtable SQL/query capabilities where applicable
- Dataflow or BigQuery integrations for analytics

Example using `cbt`:

```bash
cbt createtable sensor-data
cbt createfamily sensor-data metrics

cbt set sensor-data \
  device-101#20260718 \
  metrics:temperature=32 \
  metrics:humidity=70

cbt read sensor-data
```

The `cbt` CLI supports administrative operations and reading and writing Bigtable data. citeturn791227search1turn791227search21

## 6.5 Bigtable replication

A Bigtable instance can contain multiple clusters.

Replication can provide:

- Higher availability
- Multi-cluster routing
- Workload isolation
- Regional resilience depending on cluster placement

Replication is different from backup:

- Replication handles infrastructure failure
- Backup handles accidental deletion or corruption recovery

## 6.6 Bigtable backup and restore

Bigtable backups contain a table’s schema and data and can be restored into a new table. Automated backup policies can create periodic backups. citeturn791227search9turn791227search17

## 6.7 Bigtable versus BigQuery

| Bigtable | BigQuery |
|---|---|
| Operational NoSQL database | Analytical data warehouse |
| Low-latency row-key reads | Large-scale SQL analysis |
| High write throughput | Large aggregations |
| Application-facing | Analyst/reporting-facing |
| Limited relational behavior | Rich analytical SQL |
| Time-series serving | Historical analysis |

A common architecture is:

```text
Devices → Pub/Sub → Dataflow → Bigtable
                          └──→ BigQuery
```

Bigtable serves low-latency operational queries, while BigQuery performs analytics.

---

# 7. AlloyDB for PostgreSQL

## 7.1 What is AlloyDB?

AlloyDB is a fully managed, PostgreSQL-compatible database designed for demanding enterprise transactional and analytical workloads.

Google manages infrastructure tasks such as:

- Backup
- Security patching
- Resource allocation
- Availability
- Storage management

AlloyDB also provides AlloyDB Studio for running SQL and managing database objects from the console. citeturn735989search4

## 7.2 AlloyDB architecture

```text
AlloyDB cluster
├── Primary instance
├── Read pool instance
└── Shared distributed storage
```

### Primary instance

Handles:

- Read/write traffic
- Transactions
- Database changes

### Read pool

Provides:

- Read scaling
- Read-only query capacity
- Load-balanced read endpoints

### Shared storage

Compute and storage are separated, allowing read pools to access the same underlying database storage.

## 7.3 AlloyDB use cases

- High-performance PostgreSQL applications
- Enterprise migrations from PostgreSQL-compatible environments
- Transactional and analytical queries on operational data
- Applications requiring read pools
- AI/vector-enabled PostgreSQL use cases where supported
- High-demand SaaS backends

## 7.4 AlloyDB versus Cloud SQL for PostgreSQL

| Cloud SQL PostgreSQL | AlloyDB |
|---|---|
| General-purpose managed PostgreSQL | High-performance enterprise PostgreSQL-compatible service |
| Simpler and often less expensive | More advanced architecture |
| Good for standard applications | Good for demanding workloads |
| Read replicas | Read pools |
| Instance-attached storage model | Decoupled compute and distributed storage |
| Supports multiple SQL engines through Cloud SQL | PostgreSQL-compatible only |

## 7.5 Query AlloyDB

Using `psql`:

```bash
psql \
  "host=ALLOYDB_IP \
   port=5432 \
   dbname=postgres \
   user=postgres \
   sslmode=require"
```

SQL:

```sql
CREATE TABLE products (
    product_id BIGSERIAL PRIMARY KEY,
    product_name TEXT NOT NULL,
    price NUMERIC(10,2)
);

INSERT INTO products (
    product_name,
    price
)
VALUES
    ('Keyboard', 2500),
    ('Monitor', 18000);

SELECT *
FROM products
WHERE price > 5000;
```

## 7.6 AlloyDB backup and recovery

AlloyDB supports:

- Continuous backup and recovery
- Automated backups
- On-demand backups
- Point-in-time recovery
- Restore into a new cluster

Continuous backup is enabled on clusters according to current product behavior and supports creating a new cluster from a recent state of the source cluster. citeturn735989search5

---

# 8. Memorystore

## 8.1 What is Memorystore?

Memorystore provides managed in-memory data stores compatible with supported Redis/Valkey or Memcached offerings.

It is used for extremely low-latency access to temporary or frequently accessed data. Google’s current Memorystore documentation distinguishes the available engines and also notes lifecycle information such as the status of Memorystore for Memcached. citeturn735989search12

## 8.2 Common use cases

- Application cache
- User sessions
- Shopping cart
- Rate limiting
- Leaderboards
- Counters
- Temporary tokens
- Frequently accessed API responses

Example:

```text
Application checks cache
       |
       ├── Cache hit → Return response
       |
       └── Cache miss → Query Cloud SQL
                        → Store result in cache
                        → Return response
```

## 8.3 Cache-aside pattern

Pseudo-code:

```python
value = redis.get("product:101")

if value is None:
    value = query_cloud_sql("SELECT ...")
    redis.setex("product:101", 300, value)

return value
```

## 8.4 Memorystore is not normally the primary system of record

Cached data can expire or be evicted.

The durable source should normally remain:

- Cloud SQL
- AlloyDB
- Spanner
- Firestore
- Another persistent database

## 8.5 Example Redis commands

```bash
SET user:101:name "Tushar"
GET user:101:name

SETEX session:abc123 3600 "active"
TTL session:abc123

INCR page:view:homepage
```

## 8.6 Memorystore availability

Availability varies by selected engine and service tier.

Production configurations may include:

- Replication
- Automatic failover
- Multiple zones
- Persistence options where supported

For ACE questions, select the highly available tier when the requirement states:

- Automatic failover
- Production workload
- Zonal protection
- Reduced downtime

---

# 9. Pub/Sub

## 9.1 What is Pub/Sub?

Pub/Sub is an asynchronous messaging service that decouples producers from consumers.

Basic structure:

```text
Publisher → Topic → Subscription → Subscriber
```

Pub/Sub integrates with services such as Dataflow, BigQuery, Cloud Storage, Cloud Run, and serverless processing patterns. citeturn735989search1turn735989search9

## 9.2 Core components

### Topic

A named resource to which publishers send messages.

### Subscription

Represents delivery of topic messages to a consumer.

### Publisher

Sends messages.

### Subscriber

Receives messages.

### Acknowledgment

The subscriber confirms successful processing.

### Acknowledgment deadline

Time allowed before an unacknowledged message can be delivered again.

## 9.3 Subscription types

### Pull subscription

The subscriber requests messages.

Best for:

- Worker services
- GKE consumers
- Compute Engine consumers
- Applications needing control over processing speed

### Push subscription

Pub/Sub sends messages to an HTTPS endpoint.

Best for:

- Cloud Run
- Webhooks
- Serverless endpoints

### BigQuery subscription

Writes messages directly to BigQuery.

### Cloud Storage subscription

Writes message batches to Cloud Storage.

## 9.4 At-least-once delivery

Applications should generally be designed to tolerate duplicate messages.

Use:

- Message ID tracking
- Idempotent processing
- Deduplication table
- Transactional writes
- Exactly-once delivery features where supported and properly configured

Example deduplication logic:

```sql
SELECT *
FROM messages
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY message_id
    ORDER BY publish_time DESC
) = 1;
```

## 9.5 Pub/Sub CLI example

```bash
gcloud pubsub topics create orders-topic

gcloud pubsub subscriptions create orders-sub \
  --topic=orders-topic \
  --ack-deadline=60

gcloud pubsub topics publish orders-topic \
  --message='{"order_id":"order-101","status":"created"}'

gcloud pubsub subscriptions pull orders-sub \
  --limit=10 \
  --auto-ack
```

## 9.6 Dead-letter topic

Use a dead-letter topic when a message repeatedly fails processing.

Flow:

```text
Topic
  ↓
Subscription
  ↓ repeated failure
Dead-letter topic
  ↓
Investigation/reprocessing
```

## 9.7 Pub/Sub use cases

- Event-driven architecture
- Decoupling microservices
- Log ingestion
- IoT ingestion
- Order events
- Notification processing
- Data streaming to BigQuery
- Triggering Dataflow pipelines

---

# 10. Dataflow

## 10.1 What is Dataflow?

Dataflow is a fully managed service for unified batch and streaming data processing.

A Dataflow pipeline:

1. Reads data from one or more sources
2. Transforms the data
3. Writes the result to one or more destinations

Dataflow supports large-scale batch and streaming workloads. citeturn791227search2turn791227search11

## 10.2 Dataflow architecture

```text
Source → Transformations → Sink
```

Example:

```text
Pub/Sub
   ↓
Parse JSON
   ↓
Validate records
   ↓
Enrich records
   ↓
BigQuery
```

## 10.3 Common sources

- Pub/Sub
- Cloud Storage
- BigQuery
- Kafka
- Databases through supported connectors
- Files

## 10.4 Common destinations

- BigQuery
- Bigtable
- Cloud Storage
- Pub/Sub
- Kafka
- Supported databases

## 10.5 Batch versus streaming

### Batch

Processes bounded data.

Example:

```text
CSV files in Cloud Storage → Dataflow → BigQuery
```

### Streaming

Processes unbounded data continuously.

Example:

```text
IoT devices → Pub/Sub → Dataflow → Bigtable
```

## 10.6 Apache Beam

Dataflow executes pipelines written using Apache Beam.

Apache Beam provides abstractions such as:

- Pipeline
- PCollection
- Transform
- Source
- Sink
- Window
- Trigger

## 10.7 Dataflow templates

Google provides templates for common pipelines, such as:

- Cloud Storage to BigQuery
- Pub/Sub to BigQuery
- Pub/Sub to Cloud Storage
- Kafka to BigQuery

The Dataflow job builder also provides a console interface for creating some pipelines without writing a complete Beam application. citeturn791227search39

## 10.8 Dataflow use cases

- ETL
- ELT preparation
- Real-time fraud detection
- Log processing
- Streaming analytics
- Data cleansing
- Data movement
- File transformation

## 10.9 Pub/Sub versus Dataflow

| Pub/Sub | Dataflow |
|---|---|
| Messaging service | Processing service |
| Moves messages | Transforms data |
| Decouples systems | Executes pipeline logic |
| Retains messages temporarily | Reads, processes, and writes data |
| No complex ETL logic by itself | Supports complex transformations |

---

# 11. Managed Service for Apache Kafka

## 11.1 What is it?

Managed Service for Apache Kafka lets organizations run compatible open-source Apache Kafka clusters as a managed Google Cloud service.

It automates parts of:

- Cluster provisioning
- Infrastructure operation
- Security integration
- Scaling-related management
- Monitoring
- Kafka administration

The service runs compatible Apache Kafka and uses Kafka’s KRaft architecture rather than ZooKeeper mode. It provisions resources across three zones rather than supporting one-zone or two-zone clusters. citeturn791227search7

## 11.2 Kafka architecture

```text
Producer
   ↓
Topic
   ↓
Partitions
   ↓
Brokers
   ↓
Consumer group
```

### Broker

Kafka server that stores topic partitions.

### Topic

Logical stream of records.

### Partition

Divides the topic for parallelism.

### Producer

Writes records.

### Consumer

Reads records.

### Consumer group

Allows multiple consumers to divide partitions among themselves.

Kafka brokers receive messages from producers, and consumer groups read partitions in parallel. citeturn791227search28

## 11.3 When to choose Managed Kafka

Choose it when:

- The organization already uses Kafka APIs
- Existing applications depend on Kafka clients
- Kafka ecosystem compatibility is mandatory
- Kafka Connect or schema-registry patterns are required
- Migration should avoid major code changes
- Teams need control over Kafka topics, partitions, and consumer groups

## 11.4 Pub/Sub versus Managed Kafka

| Pub/Sub | Managed Kafka |
|---|---|
| Google-native messaging service | Managed open-source Kafka |
| Minimal infrastructure concepts | Broker, partition, topic configuration |
| Serverless-style operation | Provisioned cluster resources |
| Native GCP integration | Kafka ecosystem compatibility |
| Easier for new GCP-native applications | Better for existing Kafka applications |
| Google-managed scaling model | Kafka cluster sizing and partition planning |

Exam rule:

- New cloud-native event system with minimal operations → **Pub/Sub**
- Existing Kafka application requiring Kafka protocol compatibility → **Managed Service for Apache Kafka**

---

# 12. Choosing the correct data product

## 12.1 Decision table

| Requirement | Best product |
|---|---|
| Managed MySQL database | Cloud SQL |
| Managed SQL Server database | Cloud SQL |
| Standard PostgreSQL application | Cloud SQL |
| High-performance enterprise PostgreSQL | AlloyDB |
| Globally scalable relational database | Spanner |
| Mobile/web document database | Firestore |
| Massive low-latency time-series database | Bigtable |
| Data warehouse and analytics | BigQuery |
| Cache and user sessions | Memorystore |
| Asynchronous messaging | Pub/Sub |
| Existing Kafka workload | Managed Kafka |
| Batch/stream data transformation | Dataflow |

## 12.2 Scenario questions

### Scenario 1

An application uses MySQL and must be migrated with minimum code changes.

**Answer:** Cloud SQL for MySQL.

### Scenario 2

A global financial application requires relational transactions, strong consistency, and horizontal scaling across regions.

**Answer:** Spanner.

### Scenario 3

A mobile application needs real-time document synchronization and flexible schema.

**Answer:** Firestore.

### Scenario 4

Billions of IoT records must be written using device ID and timestamp, with millisecond-level operational reads.

**Answer:** Bigtable.

### Scenario 5

Analysts need SQL queries over 500 TB of historical sales data.

**Answer:** BigQuery.

### Scenario 6

A PostgreSQL workload requires enterprise performance and several read-only compute pools.

**Answer:** AlloyDB.

### Scenario 7

Frequently requested product records should be returned without repeatedly querying Cloud SQL.

**Answer:** Memorystore.

### Scenario 8

Services need to exchange order-created events asynchronously.

**Answer:** Pub/Sub.

### Scenario 9

An existing application uses Kafka producers, Kafka consumers, partitions, and consumer groups.

**Answer:** Managed Service for Apache Kafka.

### Scenario 10

Events from Pub/Sub must be parsed, validated, enriched, and written to BigQuery.

**Answer:** Dataflow.

---

# 13. Multi-region redundancy

## 13.1 Availability concepts

### Zonal deployment

Resource resides in one zone.

Risk:

- A zonal outage may make it unavailable.

### Regional deployment

Resource is replicated or protected across zones in one region.

Protects mainly against:

- Zonal failure

### Multi-region deployment

Data or resources span multiple regions.

Protects better against:

- Regional outages
- Large-scale infrastructure failure

## 13.2 Product comparison

| Product | High-availability approach |
|---|---|
| Cloud SQL | Regional HA primary and standby across zones |
| Firestore | Regional or multi-region location |
| BigQuery | Regional or multi-region dataset location |
| Spanner | Regional, dual-region, or multi-region configuration |
| Bigtable | Multiple clusters across zones or regions |
| AlloyDB | Regional HA and cross-region DR features/configurations |
| Memorystore | Tier/engine-specific replication and failover |
| Pub/Sub | Managed regional/global service behavior with location controls |
| Managed Kafka | Multi-zone clusters |
| Dataflow | Regional job execution with managed workers |

## 13.3 Replication does not replace backup

Replication protects against:

- Server failure
- Disk failure
- Zone failure
- Some regional failure scenarios

Backup protects against:

- Accidental deletion
- Incorrect update
- Logical corruption
- Ransomware-style logical damage
- Need to return to an older point in time

---

# 14. Backup and restore summary

| Product | Backup/recovery mechanism |
|---|---|
| Cloud SQL | Automated backups, on-demand backups, PITR, export/import |
| Firestore | Managed backup, scheduled backup, export/import, PITR where configured |
| BigQuery | Time travel, snapshots, clones, copy, export |
| Spanner | Backups, backup schedules, PITR, restore to new database |
| Bigtable | Table backups, automated backup, restore to new table |
| AlloyDB | Continuous backup, automated backup, on-demand backup, PITR |
| Memorystore | Persistence/backup capabilities depend on engine and tier |
| Pub/Sub | Retention, seek/replay, snapshots; not a database backup |
| Kafka | Topic retention and replication; external backup strategy may be required |
| Dataflow | Processing system; data protection belongs to sources and destinations |

---

# 15. Querying each database

## Cloud SQL

Use standard engine tools:

```bash
mysql
psql
sqlcmd
```

Example:

```sql
SELECT * FROM employees;
```

## BigQuery

Use:

- BigQuery Studio
- `bq` CLI
- Client libraries

```bash
bq query \
  --use_legacy_sql=false \
  'SELECT * FROM `PROJECT_ID.ace_lab.employees` LIMIT 10'
```

## Bigtable

Use:

- `cbt`
- Client libraries
- Supported query interfaces

```bash
cbt read sensor-data
```

## Spanner

Use:

- Spanner Studio
- `gcloud spanner databases execute-sql`
- Client libraries

```bash
gcloud spanner databases execute-sql ace-db \
  --instance=ace-spanner \
  --sql="SELECT * FROM Customers"
```

## Firestore

Use:

- Firestore console
- Client libraries
- REST API
- Firebase SDKs

```python
db.collection("users").where("city", "==", "Bangalore").stream()
```

## AlloyDB

Use:

- AlloyDB Studio
- `psql`
- Client libraries
- PostgreSQL-compatible tools

```sql
SELECT * FROM products;
```

---

# 16. Database Center

## 16.1 What is Database Center?

Database Center is an AI-assisted centralized dashboard for viewing database resources and database-fleet health across Google Cloud.

It provides information and recommendations related to:

- Availability
- Data protection
- Security
- Compliance
- Performance
- Capacity
- Cost

citeturn599404search8turn599404search31turn599404search36

## 16.2 Main uses

Use Database Center to:

- Discover database resources
- Identify databases without backups
- Find databases lacking HA
- Review security findings
- Identify high CPU utilization
- Review storage utilization
- View recommendations
- Ask AI-assisted questions about fleet health where supported

## 16.3 IAM

Database Center visibility depends on IAM permissions.

Permissions can be granted at:

- Project level
- Folder level
- Organization level

Organization-level permissions are useful when administrators need visibility across the complete database fleet. citeturn599404search43

## 16.4 ACE exam perspective

You may be given a requirement such as:

> An administrator needs a centralized view of all Cloud SQL, Spanner, AlloyDB, and other supported database resources, including availability and backup findings.

Answer:

**Use Database Center.**

---

# 17. Data storage cost estimation

Do not memorize every price because prices vary by:

- Region
- Edition
- Machine type
- Storage type
- Usage model
- Network traffic
- Backup retention
- Discounts

Instead, learn the cost drivers.

## 17.1 Cloud SQL cost drivers

- vCPU
- Memory
- SSD/HDD storage
- Backup storage
- HA standby
- Read replicas
- Network egress
- Licences for SQL Server
- Idle running time

Approximate formula:

```text
Monthly Cloud SQL cost =
Instance compute
+ Primary storage
+ Backup storage
+ HA/replica resources
+ Network charges
+ Licensing
```

## 17.2 Firestore cost drivers

```text
Firestore cost =
Document reads
+ Document writes
+ Document deletes
+ Data storage
+ Index storage
+ Backup/PITR
+ Network egress
```

## 17.3 BigQuery cost drivers

```text
BigQuery cost =
Storage
+ Query compute
+ Streaming ingestion
+ Data transfer
+ Optional reservations/features
```

## 17.4 Spanner cost drivers

```text
Spanner cost =
Nodes or processing units
+ Database storage
+ Backup storage
+ Data transfer
```

## 17.5 Bigtable cost drivers

```text
Bigtable cost =
Cluster nodes/compute
+ SSD/HDD storage
+ Backup storage
+ Replication clusters
+ Network traffic
```

## 17.6 AlloyDB cost drivers

```text
AlloyDB cost =
Primary compute
+ Read-pool compute
+ Database storage
+ Backup storage
+ Network traffic
```

## 17.7 Memorystore cost drivers

```text
Memorystore cost =
Provisioned memory capacity
+ Selected tier
+ Replicas
+ Network traffic
```

## 17.8 Cost estimation tools

Use:

- Google Cloud Pricing Calculator
- Billing reports
- Budgets and alerts
- BigQuery query estimator
- Database Center recommendations
- Cloud Monitoring utilization metrics
- Recommender where available

---

# Lab 1: Create Cloud SQL PostgreSQL, connect, and run queries

This lab creates:

```text
Cloud SQL PostgreSQL instance
└── Database: employee_db
    └── Table: employees
```

## Lab prerequisites

Enable APIs:

```bash
gcloud services enable \
  sqladmin.googleapis.com \
  servicenetworking.googleapis.com
```

Set variables:

```bash
export PROJECT_ID="$(gcloud config get-value project)"
export REGION="asia-south1"
export SQL_INSTANCE="ace-postgres"
export DATABASE_NAME="employee_db"
export DB_USER="appuser"
```

---

## Part A: Create Cloud SQL using Google Cloud Console

### Step 1: Open Cloud SQL

1. Open Google Cloud Console.
2. Search for **Cloud SQL**.
3. Click **Create instance**.
4. Select **PostgreSQL**.

### Step 2: Configure the instance

Use:

- Instance ID: `ace-postgres`
- Password: Create a strong PostgreSQL password
- Database version: Select a supported PostgreSQL version
- Cloud SQL edition: Suitable development edition
- Region: `asia-south1`
- Zonal availability: Single zone for lab
- Machine: Small shared-core or smallest suitable lab configuration
- Storage: SSD
- Storage size: Smallest suitable value
- Automatic storage increase: Enabled

For production:

- Select highly available regional configuration
- Use private IP
- Enable automated backup
- Enable point-in-time recovery
- Configure maintenance preferences

### Step 3: Configure connectivity

For a basic lab:

1. Open **Connections**.
2. Enable public IP.
3. Under authorized networks, add your current public IP.

Do not authorize:

```text
0.0.0.0/0
```

for a production environment.

### Step 4: Configure backup

1. Open **Data protection**.
2. Enable automated backups.
3. Enable point-in-time recovery where available.
4. Select a backup window.
5. Create the instance.

---

## Part B: Create database and user from Console

1. Open the Cloud SQL instance.
2. Select **Databases**.
3. Click **Create database**.
4. Database name:

```text
employee_db
```

5. Open **Users**.
6. Click **Add user account**.
7. Username:

```text
appuser
```

8. Set a strong password.

---

## Part C: Connect using Cloud Shell

From the instance page, click **Open Cloud Shell** or run:

```bash
gcloud sql connect ace-postgres \
  --user=postgres \
  --database=employee_db
```

The command may temporarily add the Cloud Shell public IP to the instance’s authorized networks.

Enter the PostgreSQL password when prompted.

---

## Part D: Create and query a table

```sql
CREATE TABLE employees (
    employee_id SERIAL PRIMARY KEY,
    employee_name VARCHAR(100) NOT NULL,
    department VARCHAR(50) NOT NULL,
    salary NUMERIC(10,2),
    joining_date DATE DEFAULT CURRENT_DATE
);
```

Insert records:

```sql
INSERT INTO employees (
    employee_name,
    department,
    salary,
    joining_date
)
VALUES
    ('Amit Sharma', 'Engineering', 85000, '2025-01-10'),
    ('Neha Verma', 'Finance', 70000, '2025-02-15'),
    ('Rahul Singh', 'Engineering', 92000, '2024-11-20'),
    ('Priya Gupta', 'HR', 65000, '2025-03-01');
```

Query all records:

```sql
SELECT * FROM employees;
```

Expected output:

```text
 employee_id | employee_name | department  | salary   | joining_date
-------------+---------------+-------------+----------+-------------
 1           | Amit Sharma   | Engineering | 85000.00 | 2025-01-10
 2           | Neha Verma    | Finance     | 70000.00 | 2025-02-15
 3           | Rahul Singh   | Engineering | 92000.00 | 2024-11-20
 4           | Priya Gupta   | HR          | 65000.00 | 2025-03-01
```

Aggregate query:

```sql
SELECT
    department,
    COUNT(*) AS employee_count,
    ROUND(AVG(salary), 2) AS average_salary
FROM employees
GROUP BY department
ORDER BY average_salary DESC;
```

Update:

```sql
UPDATE employees
SET salary = salary * 1.10
WHERE department = 'Engineering';
```

Delete:

```sql
DELETE FROM employees
WHERE employee_name = 'Priya Gupta';
```

Exit:

```sql
\q
```

---

## Part E: Create Cloud SQL using CLI

Set a password safely in the shell:

```bash
read -s -p "Enter PostgreSQL password: " POSTGRES_PASSWORD
echo
```

Create the instance:

```bash
gcloud sql instances create "$SQL_INSTANCE" \
  --database-version=POSTGRES_16 \
  --tier=db-f1-micro \
  --region="$REGION" \
  --storage-type=SSD \
  --storage-size=10GB \
  --storage-auto-increase \
  --availability-type=zonal
```

The exact smallest supported tier may vary by region and edition. Check currently available configurations before running the command.

Set the default PostgreSQL password:

```bash
gcloud sql users set-password postgres \
  --instance="$SQL_INSTANCE" \
  --password="$POSTGRES_PASSWORD"
```

Create database:

```bash
gcloud sql databases create "$DATABASE_NAME" \
  --instance="$SQL_INSTANCE"
```

Create application user:

```bash
read -s -p "Enter application user password: " APP_PASSWORD
echo

gcloud sql users create "$DB_USER" \
  --instance="$SQL_INSTANCE" \
  --password="$APP_PASSWORD"
```

Connect:

```bash
gcloud sql connect "$SQL_INSTANCE" \
  --user=postgres \
  --database="$DATABASE_NAME"
```

---

## Part F: Create an on-demand backup

Console:

1. Open Cloud SQL.
2. Select the instance.
3. Open **Backups**.
4. Click **Create backup**.
5. Add description:

```text
before-schema-change
```

CLI:

```bash
gcloud sql backups create \
  --instance="$SQL_INSTANCE" \
  --description="before-schema-change"
```

List backups:

```bash
gcloud sql backups list \
  --instance="$SQL_INSTANCE"
```

---

# Lab 2: Create a BigQuery dataset and load data from Cloud Storage

Architecture:

```text
Local CSV
   ↓
Cloud Storage bucket
   ↓
BigQuery load job
   ↓
BigQuery table
   ↓
SQL query
```

## Part A: Prepare environment

Enable APIs:

```bash
gcloud services enable \
  bigquery.googleapis.com \
  storage.googleapis.com
```

Set variables:

```bash
export PROJECT_ID="$(gcloud config get-value project)"
export REGION="asia-south1"
export DATASET="ace_database_lab"
export TABLE="employees"
export BUCKET="${PROJECT_ID}-ace-bq-lab"
```

Create CSV:

```bash
cat > employees.csv <<'EOF'
employee_id,employee_name,department,salary,joining_date
1,Amit Sharma,Engineering,85000,2025-01-10
2,Neha Verma,Finance,70000,2025-02-15
3,Rahul Singh,Engineering,92000,2024-11-20
4,Priya Gupta,HR,65000,2025-03-01
5,Arjun Mehta,Engineering,88000,2025-04-12
EOF
```

---

## Part B: Create bucket from Console

1. Open **Cloud Storage**.
2. Click **Create bucket**.
3. Enter a globally unique name.
4. Location type: Region
5. Region: `asia-south1`
6. Storage class: Standard
7. Access control: Uniform
8. Public access prevention: Enforced
9. Create bucket.

Upload:

1. Open bucket.
2. Click **Upload files**.
3. Select `employees.csv`.

---

## Part C: Create BigQuery dataset from Console

1. Open **BigQuery**.
2. In Explorer, locate your project.
3. Click the three-dot menu.
4. Select **Create dataset**.
5. Dataset ID:

```text
ace_database_lab
```

6. Location:

```text
asia-south1
```

The bucket and dataset should use compatible locations for Cloud Storage load operations.

7. Create dataset.

---

## Part D: Create table by loading Cloud Storage CSV

1. Open dataset `ace_database_lab`.
2. Click **Create table**.
3. Source: Google Cloud Storage.
4. Select:

```text
gs://BUCKET_NAME/employees.csv
```

5. File format: CSV.
6. Table name:

```text
employees
```

7. Schema: Enable auto-detect.
8. Header rows to skip: `1`.
9. Write preference: Write if empty.
10. Create table.

---

## Part E: Query in BigQuery Studio

```sql
SELECT *
FROM `PROJECT_ID.ace_database_lab.employees`;
```

Department summary:

```sql
SELECT
    department,
    COUNT(*) AS employee_count,
    ROUND(AVG(salary), 2) AS average_salary,
    MAX(salary) AS maximum_salary
FROM `PROJECT_ID.ace_database_lab.employees`
GROUP BY department
ORDER BY average_salary DESC;
```

Filter:

```sql
SELECT
    employee_name,
    department,
    salary
FROM `PROJECT_ID.ace_database_lab.employees`
WHERE salary > 80000
ORDER BY salary DESC;
```

---

## Part F: Perform complete lab using CLI

Create bucket:

```bash
gcloud storage buckets create "gs://${BUCKET}" \
  --location="$REGION" \
  --uniform-bucket-level-access
```

Upload file:

```bash
gcloud storage cp employees.csv "gs://${BUCKET}/employees.csv"
```

Create dataset:

```bash
bq --location="$REGION" mk \
  --dataset \
  "${PROJECT_ID}:${DATASET}"
```

Load table:

```bash
bq --location="$REGION" load \
  --source_format=CSV \
  --skip_leading_rows=1 \
  --autodetect \
  "${PROJECT_ID}:${DATASET}.${TABLE}" \
  "gs://${BUCKET}/employees.csv"
```

Check schema:

```bash
bq show \
  --schema \
  --format=prettyjson \
  "${PROJECT_ID}:${DATASET}.${TABLE}"
```

Query:

```bash
bq query \
  --use_legacy_sql=false \
  --location="$REGION" \
  "
  SELECT
      department,
      COUNT(*) AS employee_count,
      ROUND(AVG(salary), 2) AS average_salary
  FROM \`${PROJECT_ID}.${DATASET}.${TABLE}\`
  GROUP BY department
  ORDER BY average_salary DESC
  "
```

---

# Lab 3: Basic Firestore document operations

## Create Firestore database

Console:

1. Open Firestore.
2. Click **Create database**.
3. Select Firestore Native mode.
4. Select regional or multi-region location.
5. Choose production rules where applicable.
6. Create database.

Enable API:

```bash
gcloud services enable firestore.googleapis.com
```

Create database through CLI where supported:

```bash
gcloud firestore databases create \
  --database="(default)" \
  --location=asia-south1 \
  --type=firestore-native
```

## Python example

Install library:

```bash
pip install google-cloud-firestore
```

Create `firestore_lab.py`:

```python
from google.cloud import firestore


def main() -> None:
    db = firestore.Client()

    users = db.collection("users")

    users.document("user-101").set(
        {
            "name": "Tushar",
            "city": "Bangalore",
            "experience": 5,
            "active": True,
        }
    )

    users.document("user-102").set(
        {
            "name": "Amit",
            "city": "Delhi",
            "experience": 3,
            "active": True,
        }
    )

    query = users.where(filter=firestore.FieldFilter("active", "==", True))

    for document in query.stream():
        print(document.id, document.to_dict())


if __name__ == "__main__":
    main()
```

Authenticate:

```bash
gcloud auth application-default login
```

Run:

```bash
python firestore_lab.py
```

---

# Lab 4: Basic Bigtable operations using `cbt`

Bigtable can incur ongoing compute costs, so delete the instance after the lab.

Enable API:

```bash
gcloud services enable bigtable.googleapis.com
```

Set variables:

```bash
export PROJECT_ID="$(gcloud config get-value project)"
export BIGTABLE_INSTANCE="ace-bigtable"
export BIGTABLE_CLUSTER="ace-bigtable-cluster"
export BIGTABLE_ZONE="asia-south1-a"
```

Create instance:

```bash
gcloud bigtable instances create "$BIGTABLE_INSTANCE" \
  --display-name="ACE Bigtable Lab" \
  --cluster="$BIGTABLE_CLUSTER" \
  --cluster-zone="$BIGTABLE_ZONE" \
  --cluster-num-nodes=1
```

Configure `cbt`:

```bash
echo "project = ${PROJECT_ID}" > ~/.cbtrc
echo "instance = ${BIGTABLE_INSTANCE}" >> ~/.cbtrc
```

Create table:

```bash
cbt createtable sensor-data
```

Create column family:

```bash
cbt createfamily sensor-data metrics
```

Insert rows:

```bash
cbt set sensor-data \
  device-101#20260718 \
  metrics:temperature=32 \
  metrics:humidity=70

cbt set sensor-data \
  device-102#20260718 \
  metrics:temperature=29 \
  metrics:humidity=65
```

Read:

```bash
cbt read sensor-data
```

Lookup one row:

```bash
cbt lookup sensor-data device-101#20260718
```

---

# Lab 5: Pub/Sub messaging lab

Enable API:

```bash
gcloud services enable pubsub.googleapis.com
```

Create topic:

```bash
gcloud pubsub topics create database-events
```

Create subscription:

```bash
gcloud pubsub subscriptions create database-events-sub \
  --topic=database-events \
  --ack-deadline=60
```

Publish message:

```bash
gcloud pubsub topics publish database-events \
  --message='{"event":"employee_created","employee_id":101}' \
  --attribute=source=cloud-sql,environment=dev
```

Pull message:

```bash
gcloud pubsub subscriptions pull database-events-sub \
  --limit=10 \
  --auto-ack
```

---

# Lab 6: Dataflow template — Cloud Storage CSV to BigQuery

For this simple exercise, the direct BigQuery load job from Lab 2 is cheaper and easier. Dataflow is used here only to understand managed pipeline execution.

Prerequisites:

```bash
gcloud services enable \
  dataflow.googleapis.com \
  compute.googleapis.com \
  storage.googleapis.com \
  bigquery.googleapis.com
```

Typical Console steps:

1. Open Dataflow.
2. Click **Create job from template**.
3. Job name:

```text
gcs-to-bigquery-ace
```

4. Regional endpoint: `asia-south1`.
5. Select a suitable Google-provided batch template.
6. Enter:
   - Input Cloud Storage file
   - BigQuery output table
   - Temporary Cloud Storage location
7. Configure service account.
8. Run the job.
9. Monitor:
   - Worker status
   - Elements processed
   - Logs
   - Failed records

For basic CSV files, template requirements may include a schema file or JavaScript transformation depending on the selected template. Read the selected template’s required parameters before starting the job.

---

# Lab cleanup

Cloud resources can continue generating charges after the labs.

## Delete Cloud SQL

```bash
gcloud sql instances delete "$SQL_INSTANCE" \
  --quiet
```

## Delete BigQuery dataset

```bash
bq rm \
  --recursive \
  --force \
  "${PROJECT_ID}:${DATASET}"
```

## Delete Cloud Storage bucket

```bash
gcloud storage rm \
  --recursive \
  "gs://${BUCKET}"
```

## Delete Bigtable

```bash
gcloud bigtable instances delete "$BIGTABLE_INSTANCE" \
  --quiet
```

## Delete Pub/Sub resources

```bash
gcloud pubsub subscriptions delete database-events-sub

gcloud pubsub topics delete database-events
```

Firestore’s default database should not be created and deleted casually in a production project. Use a temporary training project for the Firestore lab.

---

# ACE exam revision points

1. Cloud SQL supports MySQL, PostgreSQL, and SQL Server.

2. Cloud SQL HA protects against zonal failure within a region.

3. A read replica is used for read scaling; an HA standby is used for failover.

4. Firestore is a document database, not a relational database.

5. BigQuery is an analytical warehouse, not an OLTP database.

6. Spanner provides relational SQL, strong consistency, transactions, and horizontal scaling.

7. Bigtable is optimized for high-throughput row-key access and massive time-series or key-value workloads.

8. AlloyDB is PostgreSQL-compatible and designed for demanding enterprise workloads.

9. Memorystore is normally a cache, not the durable source of truth.

10. Pub/Sub transports events; Dataflow transforms them.

11. Choose Managed Kafka when Kafka protocol and ecosystem compatibility are requirements.

12. Multi-region replication improves availability but does not replace backup.

13. For BigQuery, partition pruning and selecting only required columns reduce query cost.

14. For Firestore, reads, writes, deletes, indexes, and storage affect cost.

15. For Bigtable, row-key design is one of the most important performance considerations.

16. Database Center provides a centralized view of fleet health, security, availability, protection, performance, and cost recommendations.
