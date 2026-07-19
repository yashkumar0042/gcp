When you create a **Pub/Sub → BigQuery subscription**, Pub/Sub writes each message directly into a BigQuery table. The table schema depends on whether you want to write **only the message data** or **include Pub/Sub metadata**.

---

# Option 1: Write only the message data (Recommended)

This is the most common approach.

Suppose your publisher sends the following JSON message:

```json
{
  "employee_id": 101,
  "name": "John",
  "department": "IT",
  "salary": 65000,
  "joining_date": "2026-07-19"
}
```

Your BigQuery table schema should be:

| Column       | Type    | Mode     |
| ------------ | ------- | -------- |
| employee_id  | INT64   | REQUIRED |
| name         | STRING  | NULLABLE |
| department   | STRING  | NULLABLE |
| salary       | FLOAT64 | NULLABLE |
| joining_date | DATE    | NULLABLE |

Create the table:

```sql
CREATE TABLE demo_dataset.employee_data (
    employee_id INT64,
    name STRING,
    department STRING,
    salary FLOAT64,
    joining_date DATE
);
```

When creating the subscription:

* Delivery type → BigQuery
* Table → `demo_dataset.employee_data`
* ✔ Use topic schema (or enable schema validation if your topic has a schema)
* Write metadata → **Disabled**

The inserted row becomes:

| employee_id | name | department | salary | joining_date |
| ----------- | ---- | ---------- | ------ | ------------ |
| 101         | John | IT         | 65000  | 2026-07-19   |

---

# Option 2: Include Pub/Sub metadata

If you enable **Write metadata**, BigQuery needs additional columns.

Example table:

```sql
CREATE TABLE demo_dataset.employee_data (
    employee_id INT64,
    name STRING,
    department STRING,
    salary FLOAT64,
    joining_date DATE,

    subscription_name STRING,
    message_id STRING,
    publish_time TIMESTAMP,
    attributes JSON,
    ordering_key STRING
);
```

Example row:

| employee_id | name | department | salary | joining_date | message_id | publish_time            |
| ----------- | ---- | ---------- | ------ | ------------ | ---------- | ----------------------- |
| 101         | John | IT         | 65000  | 2026-07-19   | 8675309    | 2026-07-19 10:15:23 UTC |

---

# Option 3: No Pub/Sub schema (raw JSON)

If the topic has **no schema**, store the entire payload in a JSON column.

```sql
CREATE TABLE demo_dataset.raw_messages (
    payload JSON
);
```

Published message:

```json
{
  "name":"Alice",
  "age":25,
  "city":"London"
}
```

Stored row:

```json
{
  "name":"Alice",
  "age":25,
  "city":"London"
}
```

You can query it like:

```sql
SELECT
payload.name,
payload.age,
payload.city
FROM demo_dataset.raw_messages;
```

---

# Option 4: Store payload as STRING

```sql
CREATE TABLE demo_dataset.messages (
    payload STRING
);
```

Example row:

```
{"name":"Alice","age":25}
```

Later:

```sql
SELECT
JSON_VALUE(payload, '$.name') AS name
FROM demo_dataset.messages;
```

---

# Sample end-to-end example

### Step 1: Create topic

```bash
gcloud pubsub topics create employee-topic
```

### Step 2: Publish

```json
{
  "employee_id":1001,
  "name":"Yash",
  "department":"Cloud",
  "salary":75000
}
```

### Step 3: BigQuery table

```sql
CREATE TABLE demo.employee (
    employee_id INT64,
    name STRING,
    department STRING,
    salary FLOAT64
);
```

### Step 4: Create BigQuery subscription

```bash
gcloud pubsub subscriptions create employee-bq-sub \
    --topic=employee-topic \
    --bigquery-table=PROJECT_ID:demo.employee
```

Every published message is automatically inserted as:

| employee_id | name | department | salary |
| ----------- | ---- | ---------- | ------ |
| 1001        | Yash | Cloud      | 75000  |

---

# If your topic has a Pub/Sub schema (recommended)

If you attach an Avro or Protocol Buffer schema to the Pub/Sub topic, define the same fields in the BigQuery table. For example, for this schema:

```json
{
  "type":"record",
  "name":"Employee",
  "fields":[
    {"name":"employee_id","type":"long"},
    {"name":"name","type":"string"},
    {"name":"department","type":"string"},
    {"name":"salary","type":"double"}
  ]
}
```

Create the BigQuery table with matching types:

| Pub/Sub Type | BigQuery Type |
| ------------ | ------------- |
| string       | STRING        |
| int          | INT64         |
| long         | INT64         |
| float        | FLOAT64       |
| double       | FLOAT64       |
| boolean      | BOOL          |
| bytes        | BYTES         |
| timestamp    | TIMESTAMP     |

Matching field names and compatible data types allow Pub/Sub to write messages directly into BigQuery.

If you're creating the subscription from the Google Cloud Console, ensure the table schema is already in place (or let Pub/Sub create it when that option is available), and that the field names align with the message schema.
