# Federated Query in BigQuery: Unlocking Data Across the Cloud

Federated query in Google BigQuery is a powerful feature that enables you to analyze data from multiple sources, including external cloud storage and other Google Cloud services, without the need to copy or move the data into a BigQuery table. This comprehensive guide provides an in-depth overview of federated query, its use cases, key concepts, and how to harness its capabilities to unlock valuable insights from your data.

## Table of Contents

1. **Introduction to Federated Query in BigQuery**
   - What is Federated Query?
   - Key Concepts

2. **Use Cases for Federated Query**
   - Cross-Cloud Data Analysis
   - Real-time Data Analysis
   - Data Lake Integration
   - Multi-Cloud Data Processing
   - Hybrid Cloud Scenarios

3. **Advantages of Federated Query**
   - Simplified Data Access
   - Cost Savings
   - Real-time Insights
   - Data Lake Integration

4. **Working with Federated Query in BigQuery**
   - Supported Data Sources
   - SQL Syntax
   - Performance Considerations
   - Security and Access Control

5. **Examples of Federated Query**
   - Querying External Data in Cloud Storage
   - Analyzing Data in Cloud Bigtable
   - Combining Data from Multiple Sources
   - Real-time Streaming Analytics

## 1. Introduction to Federated Query in BigQuery

### What is Federated Query?
Federated query, also known as external query, is a feature in Google BigQuery that allows you to analyze data residing in external data sources without the need to load or import that data into BigQuery tables. It extends the capabilities of BigQuery to process and gain insights from data stored in various locations, including other cloud platforms and services.

### Key Concepts
- **External Data Sources:** These are data sources outside of BigQuery, including Google Cloud Storage, Cloud Bigtable, Google Sheets, and other external databases and file formats.
- **Federated Queries:** Queries that reference external data sources in SQL statements.
- **Data Transfer Service:** A mechanism to transfer data from external sources to BigQuery for regular updates and more efficient querying.

## 2. Use Cases for Federated Query

### Cross-Cloud Data Analysis
Federated query allows organizations to analyze data that resides in different cloud providers. For example, you can analyze data in Google Cloud Storage while running your core data processing in another cloud.

### Real-time Data Analysis
Real-time data analysis often involves multiple data sources. Federated query enables you to combine real-time data from services like Cloud Pub/Sub with historical data in BigQuery.

### Data Lake Integration
Many organizations use data lakes to store diverse data types. Federated query can be used to perform analytics on data within a data lake, keeping it in its native format.

### Multi-Cloud Data Processing
In multi-cloud environments, where data may be distributed across multiple cloud providers, federated query allows you to centralize data analysis in BigQuery.

### Hybrid Cloud Scenarios
Hybrid cloud setups, where data is stored both on-premises and in the cloud, can benefit from federated query to integrate on-premises data with cloud-based analytics.

## 3. Advantages of Federated Query

### Simplified Data Access
Federated query simplifies access to data in external sources, eliminating the need for complex data transfer operations and enabling on-the-fly analysis.

### Cost Savings
You only pay for the compute resources used to process federated queries, avoiding storage costs and data transfer charges.

### Real-time Insights
Federated query enables you to analyze real-time data alongside historical data, providing timely insights for decision-making.

### Data Lake Integration
Federated query can access data stored in data lakes in its native format, preserving data lake principles and simplifying architecture.

## 4. Working with Federated Query in BigQuery

### Supported Data Sources
BigQuery supports a variety of external data sources, including Google Cloud Storage, Cloud Bigtable, Google Sheets, external databases, and supported file formats like Avro, Parquet, and ORC.

### SQL Syntax
Federated queries use standard SQL syntax. You reference external data sources in your SQL statements using specific keywords and options.

### Performance Considerations
Query performance depends on the location and size of external data. The BigQuery Data Transfer Service can improve performance for certain use cases.

### Security and Access Control
Federated query adheres to the same access controls and security mechanisms as other BigQuery operations, ensuring data privacy and compliance.

## 5. Examples of Federated Query

### Querying External Data in Cloud Storage
An example scenario involves querying CSV files in Google Cloud Storage to combine them with structured data stored in BigQuery for analysis.

### Analyzing Data in Cloud Bigtable
You can perform real-time analytics on data in Cloud Bigtable by federating queries with BigQuery tables and external Cloud Bigtable data.

### Combining Data from Multiple Sources
Federated query allows you to join data from Cloud Storage, Cloud Bigtable, and other sources to create a unified dataset for analysis.

### Real-time Streaming Analytics
In a real-time data processing scenario, federated query enables you to analyze incoming streaming data from external sources in combination with historical data for up-to-the-minute insights.

Federated queries in BigQuery allow you to query data across multiple data sources, including Google Cloud SQL databases. To demonstrate a federated query example from BigQuery to Cloud SQL, we'll assume you have a Google Cloud project set up with both BigQuery and Cloud SQL resources. Here's a step-by-step example:

1.
# **Cloud SQL federated queries**

As a data analyst, you can query data in Cloud SQL from BigQuery using [federated queries](https://cloud.google.com/bigquery/docs/federated-queries-intro).

BigQuery Cloud SQL federation enables BigQuery to query data residing in Cloud SQL in real time, without copying or moving data. Query federation supports both MySQL (2nd generation) and PostgreSQL instances in Cloud SQL.

Alternatively, to replicate data into BigQuery, you can also use Cloud Data Fusion or [Datastream](https://cloud.google.com/datastream/docs/overview). For more about using Cloud Data Fusion, see [Replicating data from MySQL to BigQuery](https://cloud.google.com/data-fusion/docs/tutorials/replicating-data/mysql-to-bigquery).

1. **Before you begin**

- Ensure that your BigQuery administrator has created a [Cloud SQL connection](https://cloud.google.com/bigquery/docs/connect-to-sql#create-sql-connection) and [shared](https://cloud.google.com/bigquery/docs/connect-to-sql#share_connections) it with you.
- To get the permissions that you need to query a Cloud SQL instance, ask your administrator to grant you the [BigQuery Connection User ](https://cloud.google.com/iam/docs/understanding-roles#bigquery.connectionUser)(roles/bigquery.connectionUser) IAM role on your project. For more information about granting roles, see [Manage access](https://cloud.google.com/iam/docs/granting-changing-revoking-access).

You might also be able to get the required permissions through [custom roles](https://cloud.google.com/iam/docs/creating-custom-roles) or other [predefined roles](https://cloud.google.com/iam/docs/understanding-roles).

1. **Query data**

To send a federated query to Cloud SQL from a GoogleSQL query, use the [EXTERNAL\_QUERY function](https://cloud.google.com/bigquery/docs/reference/standard-sql/federated_query_functions#external_query).

Suppose that you store a customer table in BigQuery, while storing a sales table in Cloud SQL, and want to join the two tables in a single query. The following example makes a federated query to a Cloud SQL table named orders and joins the results with a BigQuery table named mydataset.customers.

SELECT c.customer\_id, c.name, rq.first\_order\_date
 FROM mydataset.customers AS c
 LEFT OUTER JOIN EXTERNAL\_QUERY(
   'us.connection\_id',
   '''SELECT customer\_id, MIN(order\_date) AS first\_order\_date
   FROM orders
   GROUP BY customer\_id''') AS rq ON rq.customer\_id = c.customer\_id
 GROUP BY c.customer\_id, c.name, rq.first\_order\_date;

The example query includes 3 parts:

1. Run the external query SELECT customer\_id, MIN(order\_date) AS first\_order\_date FROM orders GROUP BY customer\_id in the operational PostgreSQL database to get the first order date for each customer through the EXTERNAL\_QUERY() function.
2. Join the external query result table with the customers table in BigQuery by customer\_id.
3. Select customer information and first order date.

1. **View a Cloud SQL table schema**

You can use the EXTERNAL\_QUERY() function to query information\_schema tables to access database metadata, such as list all tables in the database or show table schema. The following example information\_schema queries work in both MySQL and PostgreSQL. You can learn more from [MySQL information\_schema tables](https://dev.mysql.com/doc/refman/8.0/en/information-schema-introduction.html) and [PostgreSQL information\_schema tables](https://www.postgresql.org/docs/9.1/information-schema.html).

-- List all tables in a database.
 SELECT \* FROM EXTERNAL\_QUERY("connection\_id",
 "select \* from information\_schema.tables;");

-- List all columns in a table.
 SELECT \* FROM EXTERNAL\_QUERY("connection\_id",
 "select \* from information\_schema.columns where table\_name='x';");

1. **Connection details**

The following table shows the Cloud SQL connection properties:

| **Property name** | **Value** | **Description** |
| --- | --- | --- |
| name | string | Name of the connection resource in the format: project\_id.location\_id.connection\_id. |
| --- | --- | --- |
| location | string | Location of the connection, which is the same as the Cloud SQL instance location with the following exceptions: Cloud SQL us-central1 maps to BigQuery US, Cloud SQL europe-west1 maps to BigQuery EU. |
| friendlyName | string | A user-friendly display name for the connection. |
| description | string | Description of the connection. |
| cloudSql.type | string | Can be "POSTGRES" or "MYSQL". |
| cloudSql.instanceId | string | Name of the [Cloud SQL instance](https://cloud.google.com/sql/docs/mysql/instance-settings#instance-id-2ndgen), usually in the format of:

Project-id:location-id:instance-id

 You can find the instance ID in the [Cloud SQL instance](https://console.cloud.google.com/sql/instances) detail page. |
| cloudSql.database | string | The Cloud SQL database that you want to connect to. |
| cloudSql.serviceAccountId | string | The service account configured to access the Cloud SQL database. |

The following table shows the properties for the Cloud SQL instance credential:

| **Property name** | **Value** | **Description** |
| --- | --- | --- |
| username | string | Database username |
| --- | --- | --- |
| password | string | Database password |

1. **Troubleshooting**

This section helps you troubleshoot issues you might encounter when sending a federated query to Cloud SQL.

**Issue:**  Failed to connect to database server. If you are querying a MySQL database, you might encounter the following error:

Invalid table-valued function EXTERNAL\_QUERY Failed to connect to MySQL database. Error: MysqlErrorCode(2013): Lost connection to MySQL server during query.

Alternatively, if you are querying a PostgreSQL database, you might encounter the following error:

Invalid table-valued function EXTERNAL\_QUERY Connect to PostgreSQL server failed: server closed the connection unexpectedly This probably means the server terminated abnormally before or while processing the request.

**Resolution:**  Ensure that valid credentials were used and all prerequisites were followed to create the [connection for Cloud SQL](https://cloud.google.com/bigquery/docs/connect-to-sql). Check if the service account that is automatically created when a connection to Cloud SQL is created has the Cloud SQL Client (roles/cloudsql.client) role. The service account is of the following format: service-_PROJECT\_NUMBER_@gcp-sa-bigqueryconnection.iam.gserviceaccount.com. For detailed instructions, see [Grant access to the service account](https://cloud.google.com/bigquery/docs/connect-to-sql#access-sql).

**Step 1: Set up BigQuery and Cloud SQL**

- Make sure you have a Google Cloud project with both BigQuery and Cloud SQL instances created.

**Step 2: Set Up a Connection**

- In your Google Cloud project, create a connection to your Cloud SQL instance in BigQuery. This connection allows BigQuery to access your Cloud SQL data. Follow these steps:
  - In the Google Cloud Console, go to BigQuery.
  - In the left sidebar, under "Resources," select your project and dataset.
  - In the "Details" tab, click "Create Connection."
  - Fill in the connection details for your Cloud SQL instance, including the instance name, database name, and connection name.

**Step 3: Query Data**

Now that you've set up the connection, you can run federated queries in BigQuery that access your Cloud SQL data.

Here's an example SQL query that joins data from a BigQuery table and a Cloud SQL table:

```sql
SELECT
  bqtable.column1 AS bigquery_column,
  cloudsqltable.column2 AS cloudsql_column
FROM
  `your-project.your-dataset.your-bigquery-table` AS bqtable
INNER JOIN EXTERNAL_QUERY(
  'your-project.connection-name',
  '''
  SELECT column2
  FROM your-cloudsql-table
  '''
) AS cloudsqltable
ON bqtable.join_column = cloudsqltable.join_column;
```

In this example:

- `your-project.your-dataset.your-bigquery-table` is a BigQuery table you want to join with data from Cloud SQL.
- `your-project.connection-name` is the connection name you created in Step 2.
- `your-cloudsql-table` is the name of the table in your Cloud SQL instance that you want to query.
- `join_column` is the column you want to use for the join.

This query performs an inner join between the BigQuery and Cloud SQL tables and selects specific columns from each source.

Make sure to adapt the SQL query to your specific table structures and data.

**Step 4: Run the Query**

Execute the query in BigQuery. It will access the Cloud SQL data through the external connection and return the results, which you can then analyze or use for further processing in BigQuery.

Federated queries in BigQuery open up powerful possibilities for analyzing and combining data from various sources, including Cloud SQL, without needing to manually move or replicate the data.
