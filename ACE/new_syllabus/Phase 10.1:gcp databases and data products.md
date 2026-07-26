# Phase 10: Database and Data Products — Expanded ACE Notes

The following is an **expanded version of the previous notes**. The original concepts, comparisons, commands, and labs remain valid; these additional sections add deeper theory, architectures, use cases, examples, limitations, operational considerations, and ACE exam scenarios.

---

# 1. Understanding database workloads before choosing a product

Before selecting a Google Cloud database, identify the workload type.

## 1.1 OLTP: Online Transaction Processing

OLTP systems process large numbers of small transactions.

Typical operations:

```sql
INSERT INTO orders ...
UPDATE inventory ...
SELECT customer_profile ...
DELETE FROM shopping_cart ...
```

Characteristics:

* Frequent inserts and updates
* Small number of records per query
* Low response-time requirement
* Strong transactional consistency
* Multiple concurrent users
* Normalized relational schemas are common

Examples:

* Banking transaction system
* Shopping cart
* Hotel reservation
* Employee-management portal
* Inventory-management application

Suitable Google Cloud products:

* Cloud SQL
* AlloyDB
* Spanner

---

## 1.2 OLAP: Online Analytical Processing

OLAP systems analyze large quantities of historical data.

Typical operation:

```sql
SELECT
    region,
    product_category,
    SUM(revenue) AS total_revenue
FROM sales
WHERE sale_date >= '2026-01-01'
GROUP BY region, product_category;
```

Characteristics:

* Large scans
* Aggregations
* Historical analysis
* Fewer updates than OLTP systems
* Queries can process gigabytes, terabytes, or petabytes
* Column-oriented storage is generally useful

Example workloads:

* Monthly sales reporting
* Customer-behavior analysis
* Fraud-trend analysis
* Marketing dashboards
* Machine-learning training data

Suitable product:

* BigQuery

AlloyDB can also perform operational analytics on transactional data, but BigQuery remains the primary product for large-scale analytical warehousing.

---

## 1.3 NoSQL workloads

NoSQL databases are useful when:

* The data model does not fit fixed relational tables
* Very high horizontal scale is required
* Joins are not required
* Access patterns are known in advance
* The application benefits from flexible documents or key-based access

Google Cloud NoSQL products include:

* Firestore: document database
* Bigtable: wide-column database
* Memorystore: in-memory key-value database/cache

---

## 1.4 Streaming and event-driven workloads

Streaming systems continuously process events as they arrive.

Examples:

* Customer clicks
* IoT sensor readings
* Payment events
* Application logs
* Order-created events
* GPS updates
* Stock-market events

Relevant services:

* Pub/Sub: message ingestion and delivery
* Managed Service for Apache Kafka: Kafka-compatible event streaming
* Dataflow: transformation and processing
* Bigtable: low-latency event serving
* BigQuery: analytical storage

Example architecture:

```text
Applications
    |
    v
Pub/Sub
    |
    v
Dataflow
    |
    +------------------+
    |                  |
    v                  v
BigQuery           Bigtable
Analytics          Real-time serving
```

---

# 2. Cloud SQL — Detailed Theory

## 2.1 What Cloud SQL manages

Cloud SQL is a managed relational database service for:

* MySQL
* PostgreSQL
* Microsoft SQL Server

Instead of installing a database on a Compute Engine VM, Google manages much of the database infrastructure, including provisioning, patching, backups, monitoring integration, storage management, and supported availability features. ([Google Cloud Documentation][1])

Without Cloud SQL, you would have to manage:

```text
Compute Engine VM
├── Operating system
├── Database installation
├── Database patches
├── Storage volumes
├── Backup scripts
├── Replication
├── Monitoring
├── Failover scripts
└── Security hardening
```

With Cloud SQL:

```text
Google manages
├── Infrastructure
├── Supported database patching
├── Storage management
├── Backup platform
├── HA infrastructure
└── Monitoring integration

Customer manages
├── Database schema
├── Tables and indexes
├── Users and permissions
├── SQL queries
├── Data quality
├── Application connections
└── Backup and DR configuration
```

---

## 2.2 Cloud SQL resource model

```text
Google Cloud project
└── Cloud SQL instance
    ├── Database 1
    │   ├── Tables
    │   ├── Views
    │   ├── Indexes
    │   └── Stored procedures/functions
    ├── Database 2
    └── Database users
```

A Cloud SQL **instance** is comparable to a managed database server.

A database is created inside the instance.

For example:

```text
Instance: ecommerce-postgres
├── Database: order_db
├── Database: inventory_db
└── Database: customer_db
```

---

## 2.3 Cloud SQL engines and selection

### Cloud SQL for MySQL

Choose MySQL when:

* The existing application already uses MySQL
* Migrating WordPress, Drupal, or common web applications
* Developers use MySQL-compatible libraries
* The application requires MySQL-specific syntax or features

Example:

```text
WordPress on Compute Engine
        |
        v
Cloud SQL for MySQL
```

### Cloud SQL for PostgreSQL

Choose PostgreSQL when:

* The application requires advanced SQL
* JSON/JSONB support is useful
* Strong relational functionality is required
* The application uses PostgreSQL extensions supported by Cloud SQL
* Developers need PostgreSQL compatibility

Examples:

* SaaS application
* Geospatial application
* Financial application
* Spring Boot application using PostgreSQL

### Cloud SQL for SQL Server

Choose SQL Server when:

* Migrating a Microsoft application
* The application uses SQL Server drivers
* Existing procedures or tools depend on SQL Server
* Rewriting the application is not desirable

Examples:

* .NET enterprise application
* Microsoft ERP backend
* Legacy Windows application migration

---

## 2.4 Practical Cloud SQL use cases

### Use case 1: E-commerce website

```text
Frontend
    |
    v
Application API
    |
    +--------------------+
    |                    |
    v                    v
Cloud SQL             Memorystore
Orders, users,        Product cache,
inventory             sessions
```

Cloud SQL stores:

* Customers
* Orders
* Payments
* Products
* Inventory

Memorystore caches commonly accessed product information.

### Use case 2: Employee-management application

Tables:

```text
employees
departments
salaries
attendance
leave_requests
```

Relations:

```text
departments.department_id
           |
           v
employees.department_id
```

Cloud SQL is appropriate because the data has clear relationships.

### Use case 3: Lift-and-shift migration

An organization runs MySQL on-premises and wants minimal application changes.

Recommended solution:

1. Create Cloud SQL for MySQL.
2. Import or migrate the existing database.
3. Update the application connection string.
4. Validate database users and privileges.
5. Configure backups and HA.

Cloud SQL is preferred over Spanner because Spanner is not a drop-in MySQL replacement.

---

## 2.5 Cloud SQL networking

### Public IP architecture

```text
Developer laptop
      |
      | Internet
      v
Cloud SQL public IP
```

Security mechanisms should include:

* Authorized networks
* TLS
* Strong database passwords
* IAM
* Cloud SQL Auth Proxy or connectors

Do not use:

```text
0.0.0.0/0
```

unless temporarily required in a tightly controlled lab.

### Private IP architecture

```text
Compute Engine / GKE / application
              |
              | VPC
              v
       Private services access
              |
              v
      Cloud SQL private IP
```

Private IP is preferred when:

* The database must not be internet-accessible
* The application is running inside a VPC
* Security policies require private communication
* Regulatory controls prohibit direct public connectivity

Cloud SQL private IP uses private services access or supported private service connectivity patterns, depending on the configuration. ([Google Cloud Documentation][2])

---

## 2.6 Cloud SQL Auth Proxy

The Cloud SQL Auth Proxy creates a secure connection using Google Cloud credentials.

Example flow:

```text
Application
    |
    v
Cloud SQL Auth Proxy
    |
    | IAM-authenticated encrypted connection
    v
Cloud SQL
```

Benefits:

* Avoids manual certificate management
* Uses IAM authentication for connection authorization
* Simplifies secure connectivity
* Works with public or private connectivity when network reachability exists

The proxy does not:

* Create a database user automatically
* Grant SQL privileges
* Automatically solve VPC routing problems
* Replace all network security controls

IAM controls whether the identity can connect. Database privileges control what the connected database user can do.

Example:

```text
IAM permission:
Can connect to the Cloud SQL instance

PostgreSQL permission:
Can SELECT from employees table
```

Both may be required.

---

## 2.7 Cloud SQL high availability

A regional high-availability configuration includes:

```text
Region: asia-south1

Zone A
└── Primary Cloud SQL instance

Zone B
└── Standby Cloud SQL instance
```

Data changes are synchronously replicated to the standby.

If the primary fails:

```text
Primary unavailable
        |
        v
Cloud SQL detects failure
        |
        v
Standby becomes primary
        |
        v
Application reconnects
```

Cloud SQL HA protects primarily against zonal failure within the selected region. Cross-region disaster recovery requires another strategy, such as a cross-region read replica or backup-based recovery. ([Google Cloud Documentation][3])

### HA versus read replica

| HA standby                                   | Read replica                           |
| -------------------------------------------- | -------------------------------------- |
| Used for failover                            | Used for read scaling                  |
| Synchronously replicated for HA              | Commonly asynchronously replicated     |
| Not generally used by applications for reads | Applications can run read-only queries |
| Protects against primary failure             | Reduces read load on primary           |
| Located in another zone in regional HA       | Can be same-region or cross-region     |

### Example

An application performs:

* 20,000 read queries per minute
* 500 write queries per minute

Architecture:

```text
Application writes
       |
       v
Primary Cloud SQL

Reporting/read traffic
       |
       v
Read replica
```

---

## 2.8 Backup, restore, and point-in-time recovery

Cloud SQL supports scheduled and on-demand backups. Cloud SQL backups are incremental and encrypted, and backup behavior depends on the engine and configured backup model. ([Google Cloud Documentation][4])

### Automated backup

Created according to a configured schedule.

Use for:

* Daily protection
* Operational recovery
* Routine restore requirements

### On-demand backup

Created manually.

Example use:

```text
Before:
- Major application release
- Schema migration
- Database upgrade
- Bulk data import
```

### Point-in-time recovery

Suppose this occurs:

```sql
DELETE FROM orders;
```

at 3:20 PM.

The last full backup was at 1:00 AM.

A normal backup restore could lose the day’s changes.

PITR can restore the database to a time shortly before the deletion, such as:

```text
3:19:50 PM
```

### Recovery Point Objective

RPO represents how much data the organization can afford to lose.

Example:

```text
RPO = 15 minutes
```

The recovery process must lose no more than approximately 15 minutes of data.

### Recovery Time Objective

RTO represents how quickly the service must be restored.

Example:

```text
RTO = 1 hour
```

The database must become usable within one hour.

### Backup does not equal HA

Backup:

* Helps recover old data
* Requires a restore process
* Has recovery time

HA:

* Provides automatic or managed failover
* Helps keep the database available
* Does not protect against logical deletion

---

## 2.9 Indexes in Cloud SQL

An index improves query speed by avoiding full-table scans.

Without an index:

```sql
SELECT *
FROM employees
WHERE email = 'user@example.com';
```

The database may inspect every row.

With an index:

```sql
CREATE INDEX idx_employees_email
ON employees(email);
```

The database can find the matching row more efficiently.

However, indexes:

* Consume storage
* Add overhead to inserts
* Add overhead to updates
* Require maintenance

### Example

Table size:

```text
10 million employees
```

Query:

```sql
SELECT *
FROM employees
WHERE employee_id = 999991;
```

A primary-key index makes this efficient.

### ACE focus

You are unlikely to perform deep query optimization in the ACE exam, but understand:

* Indexes improve read performance
* Too many indexes increase write cost
* Cloud SQL Insight/monitoring tools can help identify slow queries
* CPU, memory, storage, and connections must be monitored

---

## 2.10 Cloud SQL limitations

Cloud SQL may not be suitable when:

* Relational data must scale globally across very large workloads
* The application needs active relational processing across multiple regions
* Write throughput exceeds a single-primary architecture
* You require operating-system access to the database server
* Unsupported database extensions are mandatory
* The application requires petabyte-scale analytics

Alternatives:

| Requirement                 | Alternative                        |
| --------------------------- | ---------------------------------- |
| Global relational scale     | Spanner                            |
| High-performance PostgreSQL | AlloyDB                            |
| Large-scale analytics       | BigQuery                           |
| Document data               | Firestore                          |
| Time-series/key access      | Bigtable                           |
| Full OS/database control    | Compute Engine database deployment |

---

## 2.11 Cloud SQL exam scenarios

### Scenario

A company needs a managed PostgreSQL database for a regional web application. It needs automatic failover if one zone fails.

**Correct answer:** Cloud SQL for PostgreSQL with regional high availability.

### Scenario

A reporting application is slowing down the primary Cloud SQL instance.

**Correct answer:** Create a read replica and direct reporting queries to it.

### Scenario

An employee accidentally deletes records, and the database must be restored to a point 10 minutes before the deletion.

**Correct answer:** Use point-in-time recovery.

### Scenario

An application on a private GKE cluster must connect to Cloud SQL without exposing the database publicly.

**Correct answer:** Configure private IP connectivity and use a supported Cloud SQL connector or Auth Proxy.

---

# 3. Firestore — Detailed Theory

## 3.1 Firestore data model

Firestore is a NoSQL document-oriented database. It stores documents inside collections instead of storing rows inside tables. Documents contain key-value fields and can include nested objects and subcollections. ([Google Cloud Documentation][5])

Relational model:

```text
Table: users

user_id | name   | city
--------|--------|----------
101     | Tushar | Bangalore
```

Firestore model:

```text
Collection: users

Document: user-101
{
  "name": "Tushar",
  "city": "Bangalore"
}
```

A document is similar to a JSON object.

---

## 3.2 Collection and document hierarchy

```text
users
├── user-101
│   ├── name: "Tushar"
│   ├── city: "Bangalore"
│   └── orders
│       ├── order-1
│       └── order-2
└── user-102
```

Important rule:

A collection contains documents.

A document can contain:

* Fields
* Nested objects
* Arrays
* References
* Subcollections

A document cannot exist directly outside a collection.

---

## 3.3 Flexible schema

Documents inside the same collection do not have to contain identical fields.

Example:

```json
{
  "name": "Tushar",
  "city": "Bangalore"
}
```

Another document:

```json
{
  "name": "Amit",
  "city": "Delhi",
  "premium_member": true,
  "interests": ["cloud", "devops"]
}
```

This makes Firestore suitable for applications where attributes evolve.

However, flexible schema does not mean schema design is unnecessary. Applications should still maintain consistent conventions.

Poor design:

```text
Document 1: city
Document 2: CityName
Document 3: location_city
```

Better design:

```text
All documents use: city
```

---

## 3.4 Firestore real-time listeners

Firestore clients can subscribe to document or query changes.

Architecture:

```text
Mobile application
       |
       | Listen to document/query
       v
Firestore
       |
       | Change notification
       v
Application UI updates
```

Example use cases:

* Chat messages
* Live order status
* Collaborative editing
* Real-time dashboards
* Online multiplayer state
* Live ride tracking metadata

Firestore supports real-time synchronization and offline capabilities for supported mobile and web clients. ([Firebase][6])

---

## 3.5 Firestore use cases

### Use case 1: Chat application

```text
Collection: chats
└── chat-101
    ├── members: ["user-1", "user-2"]
    └── messages
        ├── message-1
        ├── message-2
        └── message-3
```

A message document:

```json
{
  "sender_id": "user-1",
  "text": "Hello",
  "sent_at": "2026-07-18T08:30:00Z"
}
```

Benefits:

* Real-time updates
* Flexible message documents
* Mobile SDK integration
* Automatic scaling

### Use case 2: Product catalog

Product fields can differ by category.

Laptop:

```json
{
  "name": "Laptop",
  "ram_gb": 16,
  "processor": "8-core",
  "screen_size": 15.6
}
```

Shoes:

```json
{
  "name": "Running Shoes",
  "size": 9,
  "material": "Mesh",
  "color": "Black"
}
```

A relational database might need many nullable columns or separate category tables. Firestore can store flexible documents.

### Use case 3: User profile service

```json
{
  "user_id": "101",
  "name": "Tushar",
  "skills": ["AWS", "GCP", "Kubernetes"],
  "social_links": {
    "youtube": "KubeKode",
    "github": "example"
  }
}
```

### Use case 4: Ride-tracking application

Firestore may store:

* Rider profile
* Ride metadata
* Join requests
* Notifications
* Chat messages

It may not be the ideal store for high-frequency GPS points at extremely large scale. Bigtable may be better for massive telemetry streams.

---

## 3.6 Denormalization in Firestore

Relational databases often normalize data.

Normalized relational example:

```text
users
-----
user_id
name

orders
------
order_id
user_id
```

Firestore frequently duplicates selected data to avoid joins.

Example order document:

```json
{
  "order_id": "order-101",
  "user_id": "user-101",
  "customer_name": "Tushar",
  "total": 5000
}
```

`customer_name` is duplicated even though it exists in the user document.

Why?

Firestore does not perform traditional relational joins. Duplicating data can reduce the number of reads.

Trade-off:

* Faster reads
* Simpler application queries
* More complex updates
* Potential inconsistency if duplicated values are not updated correctly

---

## 3.7 Firestore query design

Example:

```python
query = (
    db.collection("employees")
    .where(filter=FieldFilter("department", "==", "Engineering"))
    .where(filter=FieldFilter("salary", ">", 80000))
)
```

Firestore queries are index-driven.

Firestore generally expects queries to use available indexes rather than scanning an entire collection like a relational database might.

### Single-field index

Supports queries on one field.

Example:

```text
city == Bangalore
```

### Composite index

May be needed for combined conditions.

Example:

```text
department == Engineering
salary > 80000
ORDER BY salary
```

The error returned for a missing index typically helps direct the administrator to create the required index.

---

## 3.8 Transactions and batched writes

### Transaction

Use when operations depend on the existing value.

Example:

```text
Read inventory = 1
If inventory > 0:
    Reduce inventory to 0
    Create order
```

The transaction helps prevent two customers from buying the same final item.

### Batched write

Use when multiple writes should be committed together but do not require a previous read.

Example:

```text
Create order
Create notification
Update activity log
```

Firestore supports transactions and atomic batch operations. ([Google Cloud Documentation][7])

---

## 3.9 Firestore consistency and availability

Firestore provides strong consistency for document reads and queries in its supported operating model.

Location choice includes:

* Regional
* Multi-region

Choose regional when:

* Most users and services are in one region
* Lower regional latency is important
* Multi-region resilience is not mandatory
* Cost optimization is important

Choose multi-region when:

* Higher availability is required
* Users are geographically distributed
* Regional infrastructure failure must be tolerated better

---

## 3.10 Firestore cost example

Suppose an application has:

```text
100,000 users
Each user opens the home screen 10 times daily
Each screen query returns 20 documents
```

Reads:

```text
100,000 × 10 × 20
= 20,000,000 document reads per day
```

A poor query or overly broad real-time listener can create significant cost.

Cost optimization:

* Return only required documents
* Use pagination
* Avoid unnecessary real-time listeners
* Cache static content
* Design documents around access patterns
* Remove unneeded index exemptions/indexes where appropriate
* Avoid repeatedly reading the same unchanged documents

---

## 3.11 Firestore limitations

Firestore is not ideal when:

* Complex joins are required
* Ad hoc relational queries are common
* Large analytical scans are required
* The data model relies heavily on foreign-key constraints
* Full SQL compatibility is needed
* Large aggregate reporting is the main workload

Use BigQuery for analytics and Cloud SQL/AlloyDB/Spanner for relational operations.

---

## 3.12 Firestore exam scenarios

### Scenario

A mobile application requires offline support and real-time synchronization.

**Answer:** Firestore.

### Scenario

A product catalog contains different attributes for different product types.

**Answer:** Firestore.

### Scenario

An application needs complex joins between orders, customers, invoices, and products.

**Answer:** Cloud SQL, AlloyDB, or Spanner rather than Firestore.

### Scenario

A Firestore query combining a filter and sort fails because an index is missing.

**Answer:** Create the required composite index.

---

# 4. BigQuery — Detailed Theory

## 4.1 BigQuery architecture

BigQuery is a fully managed, serverless data platform and analytical warehouse. Its architecture separates storage from compute so that each can scale independently. ([Google Cloud Documentation][8])

Simplified architecture:

```text
Data sources
├── Cloud Storage
├── Pub/Sub
├── Databases
├── SaaS applications
└── Logs
       |
       v
BigQuery storage
       |
       v
BigQuery compute slots
       |
       v
SQL, dashboards, ML and analytics
```

You do not create or manage database servers.

---

## 4.2 Columnar storage

Traditional row-oriented storage:

```text
Row 1: employee_id, name, department, salary
Row 2: employee_id, name, department, salary
```

Columnar storage concept:

```text
employee_id column: 1, 2, 3, 4
department column: Engineering, Finance, HR, Engineering
salary column: 85000, 70000, 65000, 92000
```

Query:

```sql
SELECT department, AVG(salary)
FROM employees
GROUP BY department;
```

BigQuery can focus mainly on the `department` and `salary` columns instead of processing every column.

That is why this is better:

```sql
SELECT department, salary
FROM employees;
```

than:

```sql
SELECT *
FROM employees;
```

when only two columns are required.

---

## 4.3 BigQuery use cases

### Use case 1: Enterprise data warehouse

```text
CRM data --------\
ERP data ---------\
Website data ------> BigQuery → Looker dashboards
Sales data --------/
Marketing data ----/
```

BigQuery becomes a central analytical repository.

### Use case 2: Log analytics

```text
Application logs
      |
      v
Logging export / Pub/Sub
      |
      v
BigQuery
      |
      v
Security and operational analysis
```

Queries can identify:

* Most common errors
* Failed login patterns
* High-latency endpoints
* Traffic by country
* Resource usage trends

### Use case 3: Customer analytics

Data:

* Purchases
* Website visits
* Marketing campaigns
* Support interactions

Query:

```sql
SELECT
  customer_id,
  COUNT(DISTINCT order_id) AS orders,
  SUM(order_total) AS lifetime_value
FROM `company.sales.orders`
GROUP BY customer_id;
```

### Use case 4: BigQuery ML

BigQuery ML allows models to be created and used through GoogleSQL. ([Google Cloud Documentation][9])

Example:

```sql
CREATE OR REPLACE MODEL `sales.customer_churn_model`
OPTIONS(
  model_type='logistic_reg'
) AS
SELECT
  monthly_spend,
  support_tickets,
  account_age_days,
  churned
FROM `sales.training_data`;
```

This is useful when analysts know SQL but do not want to move data into a separate ML platform for basic model workflows.

---

## 4.4 BigQuery dataset locations

A dataset has a location.

Examples:

* `asia-south1`
* `us-central1`
* `US`
* `EU`

Data-location compatibility matters.

Example:

```text
Cloud Storage bucket: asia-south1
BigQuery dataset: asia-south1
```

This is a straightforward compatible design.

Potential problem:

```text
Cloud Storage bucket: europe-west1
BigQuery dataset: US
```

Cross-location operations may be unsupported or may require explicit data movement.

ACE exam rule:

Choose compatible storage and BigQuery locations before loading data.

---

## 4.5 Native, external, and BigLake-style access

### Native BigQuery table

Data is stored in BigQuery-managed storage.

Benefits:

* Best integration
* Strong performance
* Full table features
* Simple querying

### External table

Data remains outside BigQuery, such as in Cloud Storage.

Example:

```text
Parquet files in Cloud Storage
           |
           v
BigQuery external table
```

Benefits:

* Avoid loading or duplicating the data
* Query lake data directly

Trade-offs may include:

* Lower or variable performance
* Dependency on source files
* Some feature limitations

### Load versus external table

Choose a load job when:

* Data will be queried repeatedly
* Performance is important
* BigQuery table features are required

Choose an external table when:

* Data should remain in Cloud Storage
* It is queried occasionally
* Duplication should be avoided

---

## 4.6 Partitioning in depth

Suppose an orders table has five years of data.

Without partitioning:

```text
Query one day → potentially scan five years
```

With date partitioning:

```text
2026-07-16 partition
2026-07-17 partition
2026-07-18 partition
```

Query:

```sql
SELECT
  COUNT(*)
FROM `project.sales.orders`
WHERE order_date = '2026-07-18';
```

Only the relevant partition needs to be processed when partition pruning applies.

### Common partitioning methods

#### Time-unit column partitioning

```sql
PARTITION BY order_date
```

or:

```sql
PARTITION BY DATE(order_timestamp)
```

#### Ingestion-time partitioning

Partitions data based on when BigQuery received it.

Pseudo-columns include:

```text
_PARTITIONTIME
_PARTITIONDATE
```

#### Integer-range partitioning

Useful for numeric ranges.

Example:

```text
Customer IDs:
1–100,000
100,001–200,000
```

---

## 4.7 Clustering in depth

Clustering organizes blocks of data based on selected columns.

Example:

```sql
PARTITION BY order_date
CLUSTER BY customer_id, region
```

Query:

```sql
SELECT *
FROM `project.sales.orders`
WHERE order_date = '2026-07-18'
  AND customer_id = 'customer-101';
```

BigQuery first selects the partition and then narrows the scan using clustering.

Use clustering for columns frequently used in:

* `WHERE`
* `GROUP BY`
* Joins
* High-selectivity filters

---

## 4.8 Views and materialized views

### Logical view

A saved SQL query.

```sql
CREATE VIEW `sales.high_value_orders` AS
SELECT *
FROM `sales.orders`
WHERE order_total > 100000;
```

The underlying query runs when the view is queried.

### Materialized view

Stores precomputed results for supported queries.

Example:

```sql
CREATE MATERIALIZED VIEW `sales.daily_revenue` AS
SELECT
  order_date,
  SUM(order_total) AS total_revenue
FROM `sales.orders`
GROUP BY order_date;
```

Use when the same aggregation is queried frequently.

Benefits:

* Faster repeated queries
* Potentially lower processing cost
* Automatically maintained under supported behavior

---

## 4.9 BigQuery ingestion options

### Batch load

```text
Cloud Storage CSV/Parquet
        |
        v
BigQuery load job
```

Best when:

* Data arrives periodically
* A delay of minutes or hours is acceptable
* Lower-cost ingestion is desired

### Streaming ingestion

Best when:

* Data must be available quickly
* Dashboards need recent events
* Events arrive continuously

### BigQuery subscription

```text
Publisher → Pub/Sub topic → BigQuery subscription → BigQuery
```

Best for straightforward event delivery without complex transformation.

### Dataflow

```text
Pub/Sub → Dataflow → transform → BigQuery
```

Use when data requires:

* Parsing
* Validation
* Enrichment
* Deduplication
* Windowing
* Routing
* Complex transformations

---

## 4.10 BigQuery cost example

Suppose a table contains:

```text
20 TB total
```

A query uses:

```sql
SELECT *
FROM table;
```

It may process a large portion of 20 TB.

A better query:

```sql
SELECT
  customer_id,
  revenue
FROM table
WHERE event_date = '2026-07-18';
```

If partitioned correctly, it may process only one day and two columns.

### Cost-control methods

1. Partition tables.
2. Cluster frequently filtered columns.
3. Avoid `SELECT *`.
4. Use dry runs.
5. Set maximum bytes billed.
6. Use materialized views.
7. Expire temporary tables.
8. Use appropriate reservations for predictable workloads.
9. Use batch ingestion when real-time ingestion is unnecessary.
10. Monitor query history.

---

## 4.11 BigQuery security model

IAM can be applied at:

* Project
* Dataset
* Table
* View
* Other supported object levels

Common roles:

| Role                 | Purpose                                      |
| -------------------- | -------------------------------------------- |
| BigQuery Admin       | Broad administrative control                 |
| BigQuery Data Owner  | Manage dataset/table data and metadata       |
| BigQuery Data Editor | Create/update table data                     |
| BigQuery Data Viewer | Read data                                    |
| BigQuery Job User    | Run query jobs                               |
| BigQuery User        | Create jobs and some project-level resources |

A user often needs both:

```text
BigQuery Job User on project
+
BigQuery Data Viewer on dataset
```

The first permits running a query job. The second permits reading the data.

---

## 4.12 BigQuery recovery

Available concepts include:

* Time travel
* Table snapshots
* Table clones
* Table copy
* Dataset copy
* Export to Cloud Storage

Example accidental update:

```sql
UPDATE `sales.orders`
SET status = 'CANCELLED';
```

Recovery could involve querying historical table state and recreating the correct table, provided the historical state remains within the available retention period.

---

## 4.13 BigQuery exam scenarios

### Scenario

Analysts need to query 500 TB of sales data using SQL without managing servers.

**Answer:** BigQuery.

### Scenario

A query over a large date-partitioned table is expensive.

**Answer:** Add a partition filter and select only required columns.

### Scenario

Pub/Sub events need no transformation and must be written directly into BigQuery.

**Answer:** Use a BigQuery subscription.

### Scenario

Events must be validated and enriched before entering BigQuery.

**Answer:** Use Dataflow between Pub/Sub and BigQuery.

---

# 5. Spanner — Detailed Theory

## 5.1 Why Spanner exists

Traditional relational databases usually scale vertically:

```text
More workload
    |
    v
Increase CPU and RAM
```

At some point, one server becomes insufficient.

Manual sharding can divide data:

```text
Shard 1: Customers A–F
Shard 2: Customers G–M
Shard 3: Customers N–Z
```

But manual sharding introduces:

* Complex application logic
* Cross-shard transaction difficulty
* Rebalancing problems
* Operational overhead
* Availability challenges

Spanner provides a distributed, strongly consistent database while retaining relational schemas, SQL, secondary indexes, and ACID transactions. ([Google Cloud Documentation][10])

---

## 5.2 Spanner architecture

```text
Application
     |
     v
Spanner instance
     |
     +------------------------------+
     |                              |
     v                              v
Distributed compute             Replicated storage
```

The database is divided into ranges that can be distributed across infrastructure.

As data grows, Spanner manages the distribution rather than requiring application-managed sharding.

---

## 5.3 Strong consistency

Suppose a customer transfers ₹10,000:

```text
Account A: -₹10,000
Account B: +₹10,000
```

Both operations should either succeed or fail together.

A strongly consistent transactional database ensures applications do not observe a partially completed transaction.

Spanner supports ACID transactions:

* Atomicity
* Consistency
* Isolation
* Durability

---

## 5.4 Spanner use cases

### Use case 1: Global payment system

Requirements:

* Global user base
* Relational data
* Strong transactions
* High availability
* Horizontal scaling

Architecture:

```text
India application \
Europe application ---> Spanner multi-region
US application    /
```

### Use case 2: Global inventory

A product has five remaining units.

Customers in several countries place orders simultaneously.

The database must:

* Prevent overselling
* Maintain a consistent stock count
* Scale across global traffic

Spanner is appropriate.

### Use case 3: Online gaming backend

Data:

* Player profiles
* Inventory
* Game state
* Purchases
* Match state
* Leaderboard metadata

Spanner is used for large gaming database workloads where relational transactions and scale are needed. ([Google Cloud Documentation][11])

### Use case 4: Telecom platform

Data:

* Subscriber accounts
* Billing events
* Service plans
* Network entitlements

The workload may require very high scale and transactional consistency.

---

## 5.5 Spanner keys and hotspots

Poor primary-key design:

```text
1
2
3
4
5
```

If rows are inserted using continuously increasing keys, writes can concentrate in one key range.

This creates a hotspot.

Possible techniques:

* UUID-based keys
* Hash prefixes
* Shard identifiers
* Carefully designed composite keys

Official schema guidance describes hashing or logical sharding as techniques to distribute writes. ([Google Cloud Documentation][12])

Example:

```text
Before:
202607180001
202607180002
202607180003

After:
03#202607180001
11#202607180002
07#202607180003
```

---

## 5.6 Interleaved or related data design concepts

Spanner schema design should consider:

* Primary-key locality
* Access patterns
* Parent-child relationships
* Secondary indexes
* High-write key distribution

Example:

```text
Customers
└── Orders
    └── OrderItems
```

Rows that are frequently accessed together may be designed to preserve locality, but modern schema features and exact capabilities should be checked for the selected dialect and current product behavior.

---

## 5.7 Spanner instance configurations

### Regional

Use when:

* Users are concentrated in one region
* Low regional latency matters
* Regional availability is sufficient

### Dual-region or multi-region

Use when:

* Regional resilience is required
* Users are geographically distributed
* Global availability is important

Trade-offs:

* Higher cost
* Potentially higher write latency because writes require replicated agreement
* Better geographic resilience
* Reads can be served closer to users depending on configuration and read type

---

## 5.8 Spanner capacity

Spanner capacity can be configured using:

* Nodes
* Processing units

Processing units allow smaller capacity increments.

General rule:

* More capacity supports more workload
* Storage and compute costs increase
* Monitor CPU, storage, latency, and transaction metrics
* Avoid sustained overload

---

## 5.9 Spanner backups and PITR

Spanner supports backups, scheduled backups, restore workflows, and point-in-time recovery.

A restored backup creates a new database rather than overwriting the existing database.

Example:

```text
Source database: production-db
Backup: production-db-backup-20260718
Restore target: production-db-restored
```

After validation, the application can be redirected or data can be compared.

---

## 5.10 Spanner versus other products

### Spanner versus Cloud SQL

Choose Cloud SQL when:

* Standard MySQL/PostgreSQL/SQL Server compatibility is required
* Workload is regional
* Scale is moderate
* Cost should be minimized

Choose Spanner when:

* Horizontal relational scale is mandatory
* Multi-region relational availability is required
* Strong distributed transactions are required

### Spanner versus Bigtable

Choose Spanner when:

* SQL and transactions are required
* Multiple relational entities exist
* Secondary indexes and relational querying matter

Choose Bigtable when:

* Access is mainly by row key or key range
* Extremely high write throughput is needed
* Data is sparse/time-series
* Joins are unnecessary

### Spanner versus BigQuery

Spanner:

```text
Operational transactions
```

BigQuery:

```text
Large-scale analytics
```

---

# 6. Bigtable — Detailed Theory

## 6.1 Wide-column model

Bigtable is a wide-column NoSQL database designed for massive scale and low-latency operational access. Bigtable data is stored in rows identified by row keys, with fields grouped into column families. ([Google Cloud Documentation][13])

Example:

```text
Row key: device-101#20260718T080000

metrics:temperature = 32
metrics:humidity    = 70
location:city       = Bangalore
```

`metrics` and `location` are column families.

---

## 6.2 Sparse data

Consider three devices:

```text
Device 1: temperature, humidity
Device 2: temperature
Device 3: pressure, wind_speed
```

Bigtable does not require every row to contain every column.

Missing cells do not need to be stored like populated values.

This makes Bigtable useful for sparse datasets.

---

## 6.3 Timestamped cells

Each Bigtable cell can contain multiple timestamped versions.

Concept:

```text
metrics:temperature

08:00 → 30
08:05 → 31
08:10 → 32
```

Garbage-collection policies can remove old versions.

Examples:

* Keep the latest two versions
* Keep values for seven days
* Combine age and version rules

---

## 6.4 Bigtable use cases

### Use case 1: IoT telemetry

```text
Millions of devices
       |
       v
Pub/Sub
       |
       v
Dataflow
       |
       v
Bigtable
```

Row key example:

```text
device-101#20260718T083000
```

Queries:

* Read the latest measurements for a device
* Read a device’s data for a time range
* Retrieve readings for a selected sensor

### Use case 2: Application monitoring metrics

Data:

* CPU usage
* Memory usage
* Request latency
* Error count
* Network throughput

Row key:

```text
service-id#metric-name#timestamp
```

### Use case 3: Financial tick data

```text
symbol#date#timestamp
```

Examples:

```text
AAPL#20260718#093000001
GOOG#20260718#093000002
```

### Use case 4: Personalization feature store

Bigtable can hold low-latency features for fraud detection, recommendations, or real-time inference.

---

## 6.5 Bigtable row-key design

The row key is one of the most important design decisions.

### Bad design: sequential timestamps

```text
20260718080001
20260718080002
20260718080003
```

All recent writes may target a narrow range.

### Better design: entity prefix

```text
device-001#20260718080001
device-002#20260718080002
device-003#20260718080003
```

### Reverse timestamp

For latest-first access:

```text
device-101#MAX_TIMESTAMP_MINUS_EVENT_TIMESTAMP
```

This can place recent entries near the beginning of a device’s key range.

### Salted prefix

```text
03#device-101#timestamp
11#device-102#timestamp
```

This can distribute heavy writes but may require querying multiple ranges.

Row-key design must match query patterns.

---

## 6.6 Bigtable nodes, clusters, and instances

```text
Bigtable instance
├── Cluster A
│   └── Compute nodes
└── Cluster B
    └── Compute nodes
```

The instance is the administrative container.

Clusters provide compute capacity.

Data storage is managed separately from cluster compute.

Adding clusters enables replication.

---

## 6.7 Bigtable replication

Adding another cluster starts replication. Clusters can be placed in different zones or regions to improve availability and workload isolation. ([Google Cloud Documentation][14])

Example:

```text
Bigtable instance
├── Cluster India
└── Cluster Singapore
```

Possible traffic patterns:

### Multi-cluster routing

Applications can be routed to available clusters.

This improves availability, but replicated reads under multi-cluster routing may exhibit eventual consistency depending on operation and configuration. ([Google Cloud Documentation][15])

### Single-cluster routing

An application profile directs traffic to one cluster.

Use when:

* Stronger read-your-writes behavior is needed for the traffic pattern
* Workloads must be isolated
* A separate cluster is used for analytics or batch jobs

---

## 6.8 Bigtable backups

Bigtable supports on-demand and automated table backups. A backup can be restored into a new table. ([Google Cloud Documentation][16])

Example:

```text
Source table: sensor-data
Backup: sensor-data-backup-20260718
Restored table: sensor-data-restored
```

Replication is not a replacement for backup because an accidental delete can propagate to replicas.

---

## 6.9 Bigtable limitations

Avoid Bigtable when:

* You need relational joins
* You need general-purpose ad hoc SQL
* Foreign keys are required
* Multi-row relational transactions are central
* The dataset is very small and throughput is low
* Access patterns are not known
* Queries frequently filter arbitrary non-key columns

---

## 6.10 Bigtable exam scenarios

### Scenario

Billions of sensor readings must be ingested with low-latency lookup by sensor and time range.

**Answer:** Bigtable.

### Scenario

Analysts want to run arbitrary SQL aggregations over historical sensor data.

**Answer:** BigQuery.

A common design uses both.

### Scenario

Traffic must continue if a Bigtable cluster’s region is unavailable.

**Answer:** Add another cluster in a different region and configure an appropriate application profile/routing strategy.

---

# 7. AlloyDB for PostgreSQL — Detailed Theory

## 7.1 AlloyDB positioning

AlloyDB is a PostgreSQL-compatible managed database designed for demanding enterprise transactional and analytical workloads.

It combines a Google-built database engine with a cloud-based multi-node architecture. ([Google Cloud Documentation][17])

Choose AlloyDB when you want:

* PostgreSQL compatibility
* High transaction performance
* Read scaling
* Enterprise availability
* Operational analytics
* Advanced PostgreSQL-based workloads

---

## 7.2 AlloyDB architecture

```text
AlloyDB cluster
├── Primary instance
│   ├── Read traffic
│   └── Write traffic
│
├── Read pool 1
│   └── Read-only traffic
│
├── Read pool 2
│   └── Read-only traffic
│
└── Distributed storage layer
```

### Cluster

The top-level database resource containing the database storage and instances.

### Primary instance

Handles read/write transactions.

### Read pool

Contains one or more read nodes and provides load-balanced read-only capacity.

### Shared storage

Primary and read pools access the same underlying storage architecture, reducing the need to maintain independent full copies for each read node in the traditional manner.

---

## 7.3 AlloyDB use cases

### Use case 1: High-volume SaaS platform

Requirements:

* PostgreSQL-compatible drivers
* High transaction rate
* Several read-heavy dashboards
* High availability

Architecture:

```text
API write requests → Primary
Dashboard queries  → Read pool
Reports            → Read pool
```

### Use case 2: PostgreSQL migration

An organization runs a large PostgreSQL workload on-premises.

It wants:

* PostgreSQL compatibility
* Managed infrastructure
* Better scalability
* Read pools
* Backup and recovery

AlloyDB may be a suitable target after compatibility assessment.

### Use case 3: Hybrid transactional and analytical processing

Operational data is written to the primary.

Complex analytical queries can be directed to a read pool and may use AlloyDB’s columnar engine where suitable. AlloyDB’s columnar engine can accelerate supported analytical queries and can be enabled on primary or read pool instances. ([Google Cloud Documentation][18])

Example:

```sql
SELECT
    region,
    product_category,
    SUM(order_total)
FROM orders
GROUP BY region, product_category;
```

---

## 7.4 AlloyDB HA

AlloyDB provides managed high-availability configurations for primary instances. Read pools with multiple nodes can also be highly available. ([Google Cloud Documentation][19])

Simplified primary HA:

```text
Zone A: active node
Zone B: standby capability
Shared distributed storage
```

The exact architecture is service-managed.

---

## 7.5 AlloyDB backup and PITR

AlloyDB supports:

* Continuous backup
* Automated backups
* On-demand backups
* Point-in-time restore
* Restore into a new cluster

Continuous backup and recovery is enabled by default on clusters according to current documented product behavior and can create a new cluster from a recent state. ([Google Cloud Documentation][20])

Example:

```text
Source: production-alloydb
Restore time: 2026-07-18 08:25
Target: production-alloydb-restored
```

---

## 7.6 AlloyDB versus Cloud SQL PostgreSQL

### Choose Cloud SQL when:

* The application is small or medium
* Standard PostgreSQL performance is sufficient
* Lower operational cost is important
* Simpler architecture is preferred
* Multiple supported database engines may be considered

### Choose AlloyDB when:

* The PostgreSQL workload is demanding
* Enterprise performance is required
* Multiple read pools are useful
* Operational analytics is required
* PostgreSQL compatibility must be maintained

### Choose Spanner instead when:

* Horizontal distributed relational scaling is the dominant requirement
* Global multi-region writes are required
* PostgreSQL compatibility is not mandatory

---

# 8. Memorystore — Detailed Theory

## 8.1 Why use an in-memory data store?

Disk-based or distributed databases usually have higher latency than memory.

Repeated query:

```sql
SELECT *
FROM products
WHERE product_id = 101;
```

If executed thousands of times, it consumes database CPU and connection capacity.

With cache:

```text
First request:
Application → Cloud SQL → return result → cache result

Next requests:
Application → Memorystore → return cached result
```

This reduces database load and improves latency.

---

## 8.2 Memorystore engines

Google Cloud Memorystore offerings include managed Redis/Valkey-related products and legacy engine offerings. Product generations and lifecycle status should be checked before selecting an engine; for example, current documentation identifies Memorystore for Memcached as deprecated. ([Google Cloud Documentation][21])

For ACE preparation, focus on the general use cases:

* Cache
* Session store
* Counters
* Rate limits
* Leaderboards
* Temporary application state

---

## 8.3 Cache-aside pattern

```python
def get_product(product_id):
    cache_key = f"product:{product_id}"

    cached_product = redis.get(cache_key)

    if cached_product:
        return cached_product

    product = cloud_sql_query(product_id)

    redis.setex(cache_key, 300, serialize(product))

    return product
```

Flow:

```text
1. Check cache
2. If found, return cached data
3. If not found, query database
4. Store result with TTL
5. Return result
```

---

## 8.4 TTL

TTL means time to live.

Example:

```bash
SETEX product:101 300 '{"name":"Laptop","price":50000}'
```

The key expires after:

```text
300 seconds
```

Use short TTL for frequently changing data.

Use longer TTL for mostly static data.

---

## 8.5 Memorystore use cases

### User sessions

```text
session:abc123
{
  "user_id": "101",
  "logged_in": true
}
```

### Rate limiting

```text
api:user-101:requests:minute
```

Each request increments a counter.

If the value exceeds 100:

```text
Reject request with HTTP 429
```

### Leaderboard

Redis sorted-set concept:

```bash
ZADD game-leaderboard 5000 player-1
ZADD game-leaderboard 7200 player-2
```

### Shopping cart

Temporary cart:

```text
cart:user-101
```

The final order should still be stored in a durable database.

---

## 8.6 Cache problems

### Cache miss

Requested data is absent.

### Cache expiration

The TTL has elapsed.

### Cache eviction

The system removes keys due to memory pressure or policy.

### Stale cache

Database value changed, but cache still contains an older value.

### Cache stampede

A popular key expires and thousands of clients query the database simultaneously.

Mitigation:

* Staggered TTLs
* Request locking
* Background refresh
* Longer TTL with invalidation
* Local caching

---

## 8.7 Memorystore HA and persistence

High-availability options depend on the selected Memorystore product and configuration. Redis Cluster supports replicas for availability and read scaling, and persistence can be enabled for stronger durability. Google recommends using both HA and persistence when availability and durability are important. ([Google Cloud Documentation][22])

Still, Memorystore should generally not be treated as the sole system of record for critical business data.

---

# 9. Pub/Sub — Detailed Theory

## 9.1 Decoupling

Without Pub/Sub:

```text
Order service → directly calls email service
              → directly calls inventory service
              → directly calls analytics service
```

If the email service is down, the order service may fail or wait.

With Pub/Sub:

```text
Order service
     |
     v
orders topic
     |
     +------------------+
     |                  |
     v                  v
Email subscription   Inventory subscription
     |
     v
Analytics subscription
```

The publisher does not need to know every consumer.

---

## 9.2 Topics and subscriptions

A topic receives messages.

A subscription represents a separate message-delivery stream.

Example:

```text
Topic: order-events

Subscriptions:
- email-order-events-sub
- inventory-order-events-sub
- analytics-order-events-sub
```

Each subscription receives a copy of messages published to the topic.

When several subscribers consume from the **same subscription**, they share the work; typically one subscriber for that subscription processes a given delivered message. ([Google Cloud Documentation][23])

---

## 9.3 Message structure

A Pub/Sub message contains:

```text
Data
Attributes
Message ID
Publish timestamp
Ordering key, when used
```

Example:

```json
{
  "order_id": "order-101",
  "customer_id": "customer-20",
  "status": "created"
}
```

Attributes:

```text
source=checkout
environment=production
event_type=order_created
```

Attributes can be useful for filtering and routing.

---

## 9.4 Pull subscriptions

```text
Subscriber application
       |
       | Pull request
       v
Pub/Sub subscription
```

Best when:

* Consumer controls processing rate
* Long-running worker exists
* Flow control is required
* Running on GKE, Compute Engine, or another worker platform

---

## 9.5 Push subscriptions

```text
Pub/Sub
   |
   | HTTPS POST
   v
Cloud Run service
```

Best when:

* An HTTPS endpoint is available
* Event-driven serverless processing is desired
* Subscriber infrastructure should not continuously poll

The endpoint must return a successful response to acknowledge processing.

---

## 9.6 Export subscriptions

Pub/Sub supports export subscriptions that write directly to supported Google Cloud destinations, including BigQuery and Cloud Storage, without requiring a custom subscriber. ([Google Cloud Documentation][24])

### BigQuery subscription

Use when:

* Messages should be stored directly
* Little or no transformation is required
* Table schema or topic schema is compatible

### Cloud Storage subscription

Use when:

* Events should be archived as files
* Batch analytics will process them later
* Low-cost object storage is desired

---

## 9.7 Acknowledgment deadline

Flow:

```text
1. Subscriber receives message.
2. Ack timer starts.
3. Subscriber processes message.
4. Subscriber acknowledges.
```

If the message is not acknowledged before the effective deadline:

```text
Message can be redelivered
```

The deadline should accommodate normal processing or be extended by the subscriber library.

---

## 9.8 Duplicate processing and idempotency

Pub/Sub applications should be designed to handle possible duplicate delivery.

Unsafe logic:

```text
Receive payment event
→ Add ₹1,000 to account
```

If delivered twice:

```text
₹2,000 may be added
```

Idempotent logic:

```text
Check event_id
If already processed:
    Skip
Else:
    Apply payment
    Record event_id
```

Example table:

```text
processed_events
----------------
event_id
processed_at
```

---

## 9.9 Dead-letter topics

A message may fail because:

* Invalid JSON
* Missing required field
* Database constraint failure
* Application bug
* Dependency outage

Configuration:

```text
Main subscription
      |
      | Repeated failure
      v
Dead-letter topic
      |
      v
Dead-letter subscription
```

The operations team can investigate and replay corrected messages.

---

## 9.10 Message retention and replay

Pub/Sub can retain unacknowledged messages according to subscription configuration.

Concepts:

* Message retention
* Subscription retention
* Seek
* Snapshot
* Replay

Use cases:

* Reprocess after a subscriber bug
* Recover from downstream outage
* Test a corrected consumer

This is message replay, not a replacement for a database backup.

---

## 9.11 Pub/Sub exam scenarios

### Scenario

Several microservices need independent copies of each order event.

**Answer:** Create one topic and separate subscriptions for each microservice.

### Scenario

Ten worker pods should divide the same queue of image-processing messages.

**Answer:** Attach all workers to the same pull subscription.

### Scenario

Messages repeatedly fail and should be isolated.

**Answer:** Configure a dead-letter topic.

### Scenario

Messages need validation and enrichment before BigQuery.

**Answer:** Pub/Sub → Dataflow → BigQuery.

---

# 10. Dataflow — Detailed Theory

## 10.1 What Dataflow does

Dataflow is a managed service for unified batch and streaming processing at scale. It runs data-processing pipelines commonly written using Apache Beam. ([Google Cloud Documentation][25])

Dataflow is not a database.

It processes data between systems.

```text
Source
  |
  v
Transformations
  |
  v
Destination
```

---

## 10.2 Apache Beam model

Important concepts:

### Pipeline

The complete data-processing workflow.

### PCollection

A distributed data collection.

### Transform

An operation applied to data.

Examples:

* Map
* Filter
* Group
* Combine
* Window

### Source

Where data enters.

### Sink

Where data is written.

---

## 10.3 Batch pipeline

Bounded input:

```text
10 CSV files in Cloud Storage
```

Pipeline:

```text
Read files
   |
   v
Parse CSV
   |
   v
Remove invalid rows
   |
   v
Transform dates
   |
   v
Write to BigQuery
```

The pipeline ends after all files are processed.

---

## 10.4 Streaming pipeline

Unbounded input:

```text
Pub/Sub events continuously arriving
```

Pipeline:

```text
Read Pub/Sub
   |
   v
Parse JSON
   |
   v
Group into 5-minute windows
   |
   v
Calculate counts
   |
   v
Write BigQuery
```

The job continues running.

---

## 10.5 Windowing

Streaming data has no natural end.

Suppose events arrive continuously:

```text
08:01
08:02
08:04
08:07
08:09
```

To calculate five-minute totals, divide them into windows:

```text
08:00–08:05
08:05–08:10
```

Types of windows include:

### Fixed window

```text
Every 5 minutes
```

### Sliding window

```text
Window size: 10 minutes
Start every: 5 minutes
```

### Session window

Groups events based on periods of user activity separated by inactivity.

Example:

```text
User clicks at 08:00, 08:02, 08:03
No activity for 30 minutes
New session starts at 08:40
```

---

## 10.6 Event time versus processing time

### Event time

When the event actually occurred.

### Processing time

When Dataflow processed it.

Example:

```text
Event occurred: 08:00
Network delay
Dataflow received: 08:07
```

The event is late relative to a five-minute event-time window.

Dataflow uses watermarks, triggers, and allowed lateness concepts to handle late data.

---

## 10.7 Dataflow use cases

### Fraud detection

```text
Payments → Pub/Sub → Dataflow
                    ├── Check amount
                    ├── Check location
                    ├── Check velocity
                    └── Mark suspicious event
```

### Log processing

```text
Logs → Pub/Sub → Dataflow → BigQuery
```

Transformations:

* Parse log
* Remove sensitive values
* Extract status code
* Add service metadata
* Route invalid records

### IoT processing

```text
Devices → Pub/Sub → Dataflow
                    ├── Bigtable for latest state
                    └── BigQuery for analytics
```

### Batch migration

```text
Cloud Storage files → Dataflow → BigQuery
```

---

## 10.8 Exactly-once and at-least-once processing

Dataflow batch pipelines use exactly-once processing semantics. Streaming pipelines can use supported processing modes depending on cost, latency, source, and duplication tolerance. ([Google Cloud Documentation][26])

### Exactly-once

Each logical record contributes once to the result under supported semantics.

Useful for:

* Billing
* Financial totals
* Inventory counts

### At-least-once

A record may be processed more than once.

Useful when:

* Duplicate tolerance exists
* Lower cost or latency is important
* Downstream writes are idempotent

---

## 10.9 Dataflow templates

Templates package a pipeline for reuse.

Types include:

* Classic templates
* Flex Templates
* Google-provided templates

Examples:

* Pub/Sub to BigQuery
* Cloud Storage to BigQuery
* Kafka to BigQuery
* Pub/Sub to Cloud Storage

Use a template when:

* A standard connector flow is sufficient
* You do not want to write the entire pipeline
* Operations teams need repeatable deployment

Use custom Apache Beam when:

* Complex business logic is required
* Custom parsing is necessary
* Multiple outputs are needed
* Advanced windowing or enrichment is required

---

## 10.10 Dataflow operational concepts

Monitor:

* Job state
* Worker CPU
* Worker memory
* System lag
* Data freshness
* Watermark
* Failed elements
* Autoscaling
* Backlog
* Throughput

Streaming backlog may grow when:

* Input rate exceeds processing capacity
* Downstream database is slow
* Worker capacity is insufficient
* A transformation has a hotspot
* External API calls are slow

---

# 11. Managed Service for Apache Kafka — Detailed Theory

## 11.1 Kafka fundamentals

Kafka is an event-streaming platform.

```text
Producer
   |
   v
Topic
├── Partition 0
├── Partition 1
└── Partition 2
   |
   v
Consumer group
```

A partition is an ordered log.

Records within one partition maintain order.

Records across different partitions do not have one global order.

---

## 11.2 Consumer groups

Topic:

```text
orders
├── Partition 0
├── Partition 1
└── Partition 2
```

Consumer group:

```text
consumer-1 → Partition 0
consumer-2 → Partition 1
consumer-3 → Partition 2
```

This enables parallel processing.

If there are five consumers but only three partitions:

```text
Two consumers may remain idle
```

Partitions determine the maximum parallelism for a consumer group at a given time.

---

## 11.3 Kafka offsets

An offset identifies a record’s position in a partition.

```text
Partition 0:
Offset 0
Offset 1
Offset 2
Offset 3
```

A consumer tracks how far it has processed.

If it restarts, it can resume from a committed offset.

---

## 11.4 Managed Kafka use cases

### Existing Kafka migration

The application already uses:

* Kafka producer APIs
* Kafka consumer APIs
* Kafka topics
* Consumer groups
* Kafka Connect

Managed Kafka minimizes application redesign.

### Event-sourcing platform

Business events:

```text
OrderCreated
PaymentAuthorized
ItemShipped
OrderDelivered
```

Events are retained in Kafka topics for consumers.

### Streaming integrations

```text
Database
   |
   v
Kafka Connect
   |
   v
Kafka topic
   |
   v
Dataflow / consumer applications
```

Managed Service for Apache Kafka provides managed open-source Kafka clusters and related managed capabilities. ([Google Cloud Documentation][27])

---

## 11.5 Managed Kafka architecture

Managed Service for Apache Kafka manages cluster infrastructure, but teams still need to understand:

* Topics
* Partitions
* Retention
* Consumer groups
* Throughput
* Producer settings
* Consumer lag
* Message keys
* Schema compatibility

The service uses managed Kafka brokers and integrates with Google Cloud networking and IAM-related controls. ([Google Cloud Documentation][28])

---

## 11.6 Pub/Sub versus Managed Kafka

### Choose Pub/Sub when:

* Building a new Google Cloud-native application
* Minimal infrastructure management is desired
* Automatic service scaling is important
* Native GCP integration is the priority
* Kafka compatibility is unnecessary

### Choose Managed Kafka when:

* Existing applications use Kafka protocol
* Kafka clients must remain unchanged
* Topics and partitions must be explicitly controlled
* Kafka Connect ecosystem is required
* Consumer offset semantics are important

Google provides dedicated guidance for choosing between the two. ([Google Cloud Documentation][29])

---

# 12. Choosing the Correct Product — Expanded Decision Framework

Ask the following questions in order.

## Question 1: Is the primary workload analytical?

```text
Yes → BigQuery
No  → Continue
```

## Question 2: Is a relational schema and SQL transaction required?

```text
Yes → Cloud SQL, AlloyDB, or Spanner
No  → Continue
```

## Question 3: Is globally distributed horizontal relational scale required?

```text
Yes → Spanner
No  → Continue
```

## Question 4: Is PostgreSQL compatibility with high enterprise performance required?

```text
Yes → AlloyDB
No  → Cloud SQL
```

## Question 5: Is the application document-oriented?

```text
Yes → Firestore
No  → Continue
```

## Question 6: Is it a huge key-value, time-series, or telemetry workload?

```text
Yes → Bigtable
No  → Continue
```

## Question 7: Is it temporary low-latency cache/session data?

```text
Yes → Memorystore
```

## Question 8: Is the requirement messaging?

```text
New GCP-native workload → Pub/Sub
Kafka compatibility     → Managed Kafka
```

## Question 9: Is data transformation required?

```text
Yes → Dataflow
```

---

# 13. Expanded Product-Selection Scenarios

| Scenario                         | Product              | Reason                                              |
| -------------------------------- | -------------------- | --------------------------------------------------- |
| WordPress website                | Cloud SQL for MySQL  | Standard MySQL-compatible application               |
| Spring Boot regional application | Cloud SQL PostgreSQL | Managed relational database                         |
| Large PostgreSQL SaaS platform   | AlloyDB              | PostgreSQL compatibility and enterprise performance |
| Global banking ledger            | Spanner              | Distributed relational transactions                 |
| Mobile chat                      | Firestore            | Documents, real-time updates, mobile integration    |
| Billions of IoT readings         | Bigtable             | High-throughput key/time access                     |
| Sales warehouse                  | BigQuery             | Serverless analytics                                |
| API response cache               | Memorystore          | Low-latency in-memory access                        |
| Microservice event bus           | Pub/Sub              | Asynchronous decoupling                             |
| Existing Kafka migration         | Managed Kafka        | Kafka compatibility                                 |
| Transform streaming events       | Dataflow             | Managed stream processing                           |

---

# 14. Multi-Region Redundancy — Expanded Theory

## 14.1 Failure levels

### Instance failure

One database process or machine becomes unavailable.

### Zonal failure

A complete availability zone becomes unavailable.

### Regional failure

Multiple zones in a region become unavailable.

### Logical failure

Data is deleted or corrupted by users or applications.

Different controls handle different failures.

| Failure          | Protection                                |
| ---------------- | ----------------------------------------- |
| Process/instance | Managed restart or failover               |
| Zone             | Regional HA/multi-zone deployment         |
| Region           | Cross-region or multi-region architecture |
| Logical deletion | Backup/PITR                               |

---

## 14.2 Product examples

### Cloud SQL

* Regional HA: protects against a zonal failure
* Cross-region replica: DR option
* Backup/PITR: logical recovery

### Firestore

* Regional or multi-region database
* Managed replication
* Backup/PITR for logical recovery

### Spanner

* Regional, dual-region, or multi-region configurations
* Synchronous replication
* Backup/PITR

### Bigtable

* Multiple clusters
* Cross-zone or cross-region replication
* Backups for table recovery

### BigQuery

* Dataset location selected at creation
* Time travel, snapshots, copies, exports
* Location strategy must match compliance and workload needs

### AlloyDB

* Regional HA
* Cross-region DR capabilities
* Continuous backup and restore

---

# 15. Database Center — Expanded Notes

Database Center provides a centralized view of supported database resources and aggregates health, security, compliance, protection, performance, and capacity signals. ([Google Cloud Documentation][30])

## 15.1 Problems it helps identify

Examples:

* Production database does not have HA
* Backup is disabled
* CPU usage is persistently high
* Storage is nearly full
* Database version needs attention
* Security configuration is weak
* Database fleet contains unused resources
* Resources are not following organizational standards

## 15.2 Database-fleet view

Without Database Center:

```text
Open Cloud SQL
Open AlloyDB
Open Spanner
Open monitoring
Open recommender
Open security findings
```

With Database Center:

```text
Database Center
├── Inventory
├── Health issues
├── Recommendations
├── Security
├── Protection
├── Performance
└── Cost/capacity signals
```

Database Center also includes Gemini-assisted fleet-health interaction where supported. ([Google Cloud Documentation][31])

## 15.3 ACE scenario

An administrator manages databases across 30 projects and needs to identify all production databases without backup or high availability.

**Answer:** Use Database Center with appropriate folder or organization-level visibility.

---

# 16. Expanded Cloud SQL Lab

Add the following exercises to the previous Cloud SQL lab.

## Exercise 1: Create an index

Connect to PostgreSQL:

```bash
gcloud sql connect ace-postgres \
  --user=postgres \
  --database=employee_db
```

Create index:

```sql
CREATE INDEX idx_employees_department
ON employees(department);
```

Display indexes:

```sql
\d employees
```

Run query:

```sql
EXPLAIN
SELECT *
FROM employees
WHERE department = 'Engineering';
```

For a very small table, PostgreSQL may still choose a sequential scan because scanning a few rows is cheaper than using the index. That is expected.

---

## Exercise 2: Create a second related table

```sql
CREATE TABLE departments (
    department_id SERIAL PRIMARY KEY,
    department_name VARCHAR(100) UNIQUE NOT NULL,
    location VARCHAR(100)
);
```

Insert data:

```sql
INSERT INTO departments (
    department_name,
    location
)
VALUES
    ('Engineering', 'Bangalore'),
    ('Finance', 'Mumbai'),
    ('HR', 'Delhi');
```

Run a join:

```sql
SELECT
    e.employee_name,
    e.department,
    d.location
FROM employees e
JOIN departments d
    ON e.department = d.department_name;
```

This demonstrates why a relational database is useful.

---

## Exercise 3: Create a read-only user

```sql
CREATE USER reporting_user
WITH PASSWORD 'ReplaceWithStrongPassword';
```

Grant connection:

```sql
GRANT CONNECT ON DATABASE employee_db
TO reporting_user;
```

Grant schema usage:

```sql
GRANT USAGE ON SCHEMA public
TO reporting_user;
```

Grant table read access:

```sql
GRANT SELECT ON ALL TABLES IN SCHEMA public
TO reporting_user;
```

Set future-table permissions:

```sql
ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT SELECT ON TABLES TO reporting_user;
```

This demonstrates least privilege.

---

## Exercise 4: Export Cloud SQL data

Create bucket:

```bash
export EXPORT_BUCKET="${PROJECT_ID}-cloudsql-export"

gcloud storage buckets create "gs://${EXPORT_BUCKET}" \
  --location="$REGION" \
  --uniform-bucket-level-access
```

The Cloud SQL service agent needs appropriate bucket permissions for export.

Export:

```bash
gcloud sql export sql "$SQL_INSTANCE" \
  "gs://${EXPORT_BUCKET}/employee-db-export.sql.gz" \
  --database="$DATABASE_NAME"
```

Use export for:

* Migration
* Portability
* Long-term archival
* External inspection

Use backup/PITR for normal operational recovery.

---

## Exercise 5: Observe monitoring metrics

In the Console:

1. Open Cloud SQL.
2. Select the instance.
3. Open **System insights** or monitoring.
4. Review:

   * CPU utilization
   * Memory utilization
   * Storage usage
   * Active connections
   * Read/write operations
   * Query latency
5. Run repeated queries and observe metrics.

---

# 17. Expanded BigQuery Lab

## Exercise 1: Define schema explicitly

Instead of auto-detect:

```bash
bq load \
  --source_format=CSV \
  --skip_leading_rows=1 \
  "${PROJECT_ID}:${DATASET}.employees_explicit" \
  "gs://${BUCKET}/employees.csv" \
  employee_id:INTEGER,employee_name:STRING,department:STRING,salary:NUMERIC,joining_date:DATE
```

Explicit schema is safer for production because auto-detection may infer an unexpected type.

---

## Exercise 2: Create a partitioned orders table

```sql
CREATE OR REPLACE TABLE `PROJECT_ID.ace_database_lab.orders_partitioned`
(
    order_id STRING,
    customer_id STRING,
    region STRING,
    order_total NUMERIC,
    order_date DATE
)
PARTITION BY order_date
CLUSTER BY customer_id, region;
```

Insert data:

```sql
INSERT INTO `PROJECT_ID.ace_database_lab.orders_partitioned`
VALUES
  ('order-1', 'customer-1', 'India', 5000, '2026-07-17'),
  ('order-2', 'customer-2', 'India', 8000, '2026-07-18'),
  ('order-3', 'customer-1', 'Singapore', 12000, '2026-07-18'),
  ('order-4', 'customer-3', 'India', 6000, '2026-07-18');
```

Query one partition:

```sql
SELECT
    region,
    SUM(order_total) AS revenue
FROM `PROJECT_ID.ace_database_lab.orders_partitioned`
WHERE order_date = '2026-07-18'
GROUP BY region;
```

---

## Exercise 3: Compare query cost

Query all columns:

```sql
SELECT *
FROM `PROJECT_ID.ace_database_lab.orders_partitioned`;
```

Query selected columns and partition:

```sql
SELECT
  customer_id,
  order_total
FROM `PROJECT_ID.ace_database_lab.orders_partitioned`
WHERE order_date = '2026-07-18';
```

Before running, observe the estimated bytes processed in BigQuery Studio.

---

## Exercise 4: Create a view

```sql
CREATE OR REPLACE VIEW
`PROJECT_ID.ace_database_lab.engineering_employees`
AS
SELECT
    employee_id,
    employee_name,
    salary
FROM `PROJECT_ID.ace_database_lab.employees`
WHERE department = 'Engineering';
```

Query:

```sql
SELECT *
FROM `PROJECT_ID.ace_database_lab.engineering_employees`;
```

---

## Exercise 5: Create a table snapshot

```sql
CREATE SNAPSHOT TABLE
`PROJECT_ID.ace_database_lab.employees_snapshot`
CLONE
`PROJECT_ID.ace_database_lab.employees`;
```

Use snapshots before:

* Bulk updates
* Schema migration
* Deletion
* Major transformation

Confirm the exact snapshot syntax and supported retention behavior in the active BigQuery environment.

---

# 18. New Mini Lab: Firestore Query and Update

Create documents:

```python
from google.cloud import firestore
from google.cloud.firestore_v1.base_query import FieldFilter

db = firestore.Client()

employees = db.collection("employees")

employees.document("employee-101").set({
    "name": "Amit",
    "department": "Engineering",
    "salary": 85000,
    "active": True
})

employees.document("employee-102").set({
    "name": "Neha",
    "department": "Finance",
    "salary": 70000,
    "active": True
})
```

Update a field:

```python
employees.document("employee-101").update({
    "salary": 90000
})
```

Query:

```python
query = employees.where(
    filter=FieldFilter("department", "==", "Engineering")
)

for document in query.stream():
    print(document.id, document.to_dict())
```

Delete:

```python
employees.document("employee-102").delete()
```

ACE learning:

* Collection
* Document
* Field
* Document ID
* Query
* Update
* Delete
* Index-driven filtering

---

# 19. New Mini Lab: Pub/Sub with Multiple Subscriptions

Create topic:

```bash
gcloud pubsub topics create order-events
```

Create two subscriptions:

```bash
gcloud pubsub subscriptions create email-order-sub \
  --topic=order-events

gcloud pubsub subscriptions create analytics-order-sub \
  --topic=order-events
```

Publish:

```bash
gcloud pubsub topics publish order-events \
  --message='{"order_id":"order-101","status":"created"}'
```

Pull from email subscription:

```bash
gcloud pubsub subscriptions pull email-order-sub \
  --limit=10 \
  --auto-ack
```

Pull from analytics subscription:

```bash
gcloud pubsub subscriptions pull analytics-order-sub \
  --limit=10 \
  --auto-ack
```

Observation:

Both subscriptions receive their own copy of the event.

Now create two terminals pulling from the **same** subscription. The messages are shared among subscribers rather than copied independently to each worker.

---

# 20. Final ACE Revision Matrix

| Requirement phrase in question            | Likely answer                              |
| ----------------------------------------- | ------------------------------------------ |
| Existing MySQL/PostgreSQL/SQL Server      | Cloud SQL                                  |
| Automatic zonal database failover         | Cloud SQL HA                               |
| Read-heavy Cloud SQL workload             | Read replica                               |
| High-performance PostgreSQL               | AlloyDB                                    |
| PostgreSQL read pools                     | AlloyDB                                    |
| Globally scalable relational transactions | Spanner                                    |
| Strong global consistency                 | Spanner                                    |
| Mobile document database                  | Firestore                                  |
| Real-time mobile synchronization          | Firestore                                  |
| Massive telemetry and time-series         | Bigtable                                   |
| Row-key access                            | Bigtable                                   |
| Data warehouse                            | BigQuery                                   |
| Petabyte-scale analytics                  | BigQuery                                   |
| Cache, sessions, leaderboard              | Memorystore                                |
| Asynchronous message delivery             | Pub/Sub                                    |
| Multiple independent consumers            | Multiple Pub/Sub subscriptions             |
| Existing Kafka client compatibility       | Managed Kafka                              |
| Batch/stream transformation               | Dataflow                                   |
| Central database fleet view               | Database Center                            |
| Recover accidental deletion               | Backup or PITR                             |
| Survive zonal outage                      | HA/multi-zone                              |
| Survive regional outage                   | Cross-region or multi-region design        |
| Reduce BigQuery query cost                | Partitioning, clustering, selected columns |
| Protect private database access           | Private IP and least-privilege IAM         |

[1]: https://docs.cloud.google.com/sql/docs/introduction?utm_source=chatgpt.com "Cloud SQL overview"
[2]: https://docs.cloud.google.com/sql/docs/mysql/private-ip?utm_source=chatgpt.com "Learn about using private IP | Cloud SQL for MySQL"
[3]: https://docs.cloud.google.com/sql/docs/postgres/high-availability?utm_source=chatgpt.com "About high availability | Cloud SQL for PostgreSQL"
[4]: https://docs.cloud.google.com/sql/docs/mysql/backup-recovery/backups?utm_source=chatgpt.com "Cloud SQL backups overview | Cloud SQL for MySQL"
[5]: https://docs.cloud.google.com/firestore/native/docs/data-model?utm_source=chatgpt.com "Data model | Firestore in Native mode"
[6]: https://firebase.google.com/docs/firestore?utm_source=chatgpt.com "Firestore | Firebase - Google"
[7]: https://docs.cloud.google.com/firestore/native/docs/manage-data/add-data?utm_source=chatgpt.com "Add and update data | Firestore in Native mode"
[8]: https://docs.cloud.google.com/bigquery/docs/introduction?utm_source=chatgpt.com "BigQuery overview"
[9]: https://docs.cloud.google.com/bigquery/docs/bqml-introduction?utm_source=chatgpt.com "Introduction to ML in BigQuery"
[10]: https://docs.cloud.google.com/spanner/docs/whitepapers/life-of-reads-and-writes?utm_source=chatgpt.com "Life of Spanner Reads & Writes"
[11]: https://docs.cloud.google.com/spanner/docs/best-practices-gaming-database?utm_source=chatgpt.com "Best practices for using Spanner as a gaming database"
[12]: https://docs.cloud.google.com/spanner/docs/schema-design?utm_source=chatgpt.com "Schema design best practices | Spanner"
[13]: https://docs.cloud.google.com/bigtable/docs/overview?hl=en&utm_source=chatgpt.com "Bigtable overview  |  Google Cloud Documentation"
[14]: https://docs.cloud.google.com/bigtable/docs/replication-overview?utm_source=chatgpt.com "Replication overview  |  Bigtable  |  Google Cloud Documentation"
[15]: https://docs.cloud.google.com/bigtable/docs/replication-performance?utm_source=chatgpt.com "Replication and performance  |  Bigtable  |  Google Cloud Documentation"
[16]: https://docs.cloud.google.com/bigtable/docs/backups?utm_source=chatgpt.com "Bigtable backups overview  |  Google Cloud Documentation"
[17]: https://docs.cloud.google.com/alloydb/docs/overview?hl=en&utm_source=chatgpt.com "AlloyDB overview  |  AlloyDB for PostgreSQL  |  Google Cloud Documentation"
[18]: https://docs.cloud.google.com/alloydb/docs/columnar-engine/about?utm_source=chatgpt.com "About the AlloyDB columnar engine  |  AlloyDB for PostgreSQL  |  Google Cloud Documentation"
[19]: https://docs.cloud.google.com/alloydb/docs/high-availability?hl=en&utm_source=chatgpt.com "AlloyDB high availability overview  |  AlloyDB for PostgreSQL  |  Google Cloud Documentation"
[20]: https://docs.cloud.google.com/alloydb/docs/backup/overview?utm_source=chatgpt.com "Data backup and recovery overview  |  AlloyDB for PostgreSQL  |  Google Cloud Documentation"
[21]: https://docs.cloud.google.com/memorystore/docs?utm_source=chatgpt.com "Memorystore  |  Google Cloud Documentation"
[22]: https://docs.cloud.google.com/memorystore/docs/cluster/ha-and-replicas?utm_source=chatgpt.com "High availability and replicas  |  Memorystore for Redis Cluster  |  Google Cloud Documentation"
[23]: https://docs.cloud.google.com/pubsub/docs/pubsub-basics?utm_source=chatgpt.com "Overview of the Pub/Sub service  |  Google Cloud Documentation"
[24]: https://docs.cloud.google.com/pubsub/docs/subscription-overview?utm_source=chatgpt.com "Subscription overview  |  Pub/Sub  |  Google Cloud Documentation"
[25]: https://docs.cloud.google.com/dataflow/docs/overview?utm_source=chatgpt.com "Dataflow overview  |  Google Cloud Documentation"
[26]: https://docs.cloud.google.com/dataflow/docs/guides/streaming-modes?utm_source=chatgpt.com "Set the pipeline streaming mode  |  Cloud Dataflow  |  Google Cloud Documentation"
[27]: https://docs.cloud.google.com/managed-service-for-apache-kafka/docs/overview?utm_source=chatgpt.com "Managed Service for Apache Kafka overview  |  Google Cloud Documentation"
[28]: https://docs.cloud.google.com/managed-service-for-apache-kafka/docs/brokers?utm_source=chatgpt.com "Overview of brokers in Managed Service for Apache Kafka  |  Google Cloud Managed Service for Apache Kafka  |  Google Cloud Documentation"
[29]: https://docs.cloud.google.com/managed-service-for-apache-kafka/docs/choose-kafka-pubsub?utm_source=chatgpt.com "Choose Cloud Managed Service for Apache Kafka or Pub/Sub  |  Google Cloud Documentation"
[30]: https://docs.cloud.google.com/database-center/docs/reference?utm_source=chatgpt.com "Overview  |  Database Center Documentation  |  Google Cloud Documentation"
[31]: https://docs.cloud.google.com/database-center/docs/overview?authuser=14&hl=en&utm_source=chatgpt.com "Database Center overview  |  Google Cloud Documentation"
