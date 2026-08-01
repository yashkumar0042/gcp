
# Phase 18: Observability and Logging

Operations, monitoring, and troubleshooting are core ACE responsibilities. The exam generally tests whether you can choose the correct signal, find the relevant information, create alerts, route logs, and troubleshoot a failing workload—not whether you can design an advanced enterprise observability platform.

---

## 1. Google Cloud Observability overview

**Google Cloud Observability** is the collection of services used to understand the health, performance, availability, and behavior of applications and infrastructure.

The major telemetry signals are:

| Signal | What it tells you | Google Cloud service |
|---|---|---|
| Metrics | What is happening numerically | Cloud Monitoring |
| Logs | What events occurred | Cloud Logging |
| Traces | Where time was spent across a request | Cloud Trace |
| Profiles | Which functions consume CPU or memory | Cloud Profiler |
| Errors | Which application errors are recurring | Error Reporting |
| Uptime checks | Whether an endpoint is reachable | Cloud Monitoring |
| Health events | Whether Google Cloud itself has an incident | Personalized Service Health |

Cloud Monitoring automatically collects performance information from most Google Cloud services. It can also ingest custom, Prometheus, OpenTelemetry, and log-based metrics. citeturn275060search1turn275060search11

### Observability versus monitoring

**Monitoring** tells you that something is wrong.

Example:

```text
CPU utilization is above 90%.
```

**Observability** helps you determine why it is wrong.

Example:

```text
CPU increased because a new application version introduced an expensive loop.
```

A practical investigation normally looks like this:

```text
Alert
  ↓
Metric confirms abnormal behavior
  ↓
Logs show errors
  ↓
Trace identifies slow dependency
  ↓
Profiler identifies expensive function
  ↓
Fix and verify
```

### Golden signals

For application monitoring, remember these four common signals:

1. **Latency** – how long requests take.
2. **Traffic** – how many requests the system receives.
3. **Errors** – how many requests fail.
4. **Saturation** – how close the resource is to its limit.

Example:

| Signal | Example metric |
|---|---|
| Latency | HTTP request duration |
| Traffic | Requests per second |
| Errors | HTTP 5xx count |
| Saturation | CPU, memory, queue depth |

---

# 2. Cloud Monitoring

Cloud Monitoring collects, stores, displays, and alerts on time-series data.

A time series contains:

```text
Metric + monitored resource + labels + values over time
```

Example:

```text
Metric:
compute.googleapis.com/instance/cpu/utilization

Resource:
gce_instance

Labels:
instance_id, zone, project_id

Values:
0.25, 0.40, 0.92...
```

## Main capabilities

Cloud Monitoring provides:

- Metrics Explorer
- Custom dashboards
- Alerting policies
- Notification channels
- Uptime checks
- Service monitoring
- SLO monitoring
- Prometheus integration
- Cross-project metrics scopes

## Metrics Explorer

Metrics Explorer is used for temporary investigation and chart creation.

Typical steps:

1. Open **Monitoring → Metrics Explorer**.
2. Select a resource type.
3. Select a metric.
4. Add filters.
5. Select an aggregation.
6. Change alignment period.
7. Save the chart to a dashboard if needed.

### Example

To check CPU across VMs:

```text
Resource type: VM Instance
Metric: CPU utilization
Group by: instance_name
Aggregator: Mean
Alignment period: 1 minute
```

## Dashboards

Dashboards are persistent collections of charts and observability widgets.

Two main types:

### Preconfigured dashboards

Google automatically provides dashboards for supported services such as:

- Compute Engine
- GKE
- Cloud SQL
- Cloud Run
- Load Balancing
- Pub/Sub

### Custom dashboards

You create these for application-specific views.

Example production dashboard:

```text
HTTP request count
HTTP 5xx rate
P95 latency
VM CPU
VM memory
Database connections
Pub/Sub backlog
```

## Metrics scopes

A metrics scope lets one project view monitoring data from multiple projects.

Typical design:

```text
Monitoring project
   ├── Development project
   ├── Staging project
   └── Production project
```

This is useful for centralized operations.

**ACE exam point:** Metrics scope changes which projects can be viewed together. It does not move or copy the source metric data.

---

# 3. Create a Monitoring alert

An alerting policy evaluates a condition against metric or log data and opens an incident when the condition is met.

An alerting policy normally contains:

```text
Condition
Notification channel
Documentation
Incident behavior
```

Cloud Monitoring alerting supports both metric-based and log-based conditions. citeturn914778view2

## Important alert concepts

### Threshold

The value that triggers the alert.

Example:

```text
CPU utilization > 80%
```

### Duration or retest window

How long the condition must remain true.

Example:

```text
CPU > 80% for 5 minutes
```

This prevents alerts from being triggered by a brief spike.

### Alignment period

The period over which raw metric points are combined.

Example:

```text
Calculate one average every 5 minutes.
```

### Per-series aligner

How individual time-series values are combined within an alignment period.

Examples:

- Mean
- Maximum
- Sum
- Rate
- Delta

### Cross-series reducer

How multiple resources are combined.

Examples:

- Average CPU across all VMs
- Maximum CPU across all VMs
- Sum of requests from all instances

### Notification channels

Possible channels include:

- Email
- SMS, where supported
- Google Cloud mobile application
- Pub/Sub
- Webhook
- Slack
- PagerDuty

## GUI: Create a CPU alert

1. Open **Monitoring → Alerting**.
2. Click **Create policy**.
3. Click **Select a metric**.
4. Choose:
   - Resource: `VM Instance`
   - Metric: `CPU utilization`
5. Add a resource filter for the target VM if required.
6. Set:
   - Condition: `Above threshold`
   - Threshold: `0.80`
   - Retest window: `5 minutes`
7. Select a notification channel.
8. Add documentation such as:

```text
CPU is above 80%. Check active processes, recent deployments,
application traffic, and instance sizing.
```

9. Name the policy:

```text
High CPU - ACE VM
```

10. Click **Create policy**.

## CLI: Create a CPU alert

Enable the API:

```bash
gcloud services enable monitoring.googleapis.com
```

Create `cpu-alert-policy.json`:

```json
{
  "displayName": "High CPU - ACE VM",
  "documentation": {
    "content": "CPU utilization is above 80% for 5 minutes. Check active processes and recent deployments.",
    "mimeType": "text/markdown"
  },
  "combiner": "OR",
  "conditions": [
    {
      "displayName": "VM CPU above 80%",
      "conditionThreshold": {
        "filter": "resource.type=\"gce_instance\" AND metric.type=\"compute.googleapis.com/instance/cpu/utilization\"",
        "comparison": "COMPARISON_GT",
        "thresholdValue": 0.8,
        "duration": "300s",
        "aggregations": [
          {
            "alignmentPeriod": "60s",
            "perSeriesAligner": "ALIGN_MEAN"
          }
        ],
        "trigger": {
          "count": 1
        }
      }
    }
  ],
  "alertStrategy": {
    "autoClose": "1800s"
  },
  "enabled": true
}
```

Create the policy:

```bash
gcloud monitoring policies create \
  --policy-from-file=cpu-alert-policy.json
```

List policies:

```bash
gcloud monitoring policies list
```

Describe a policy:

```bash
gcloud monitoring policies describe POLICY_ID
```

Delete it:

```bash
gcloud monitoring policies delete POLICY_ID
```

---

# 4. Resource metrics

Resource metrics are measurements collected for Google Cloud resources.

Examples:

| Resource | Common metrics |
|---|---|
| Compute Engine | CPU, disk bytes, network bytes |
| GKE | Pod CPU, memory, restart count |
| Cloud Run | Request count, latency, instance count |
| Cloud SQL | CPU, memory, connections, disk utilization |
| Pub/Sub | Unacknowledged messages, oldest message age |
| Load Balancer | Request count, latency, response codes |
| Cloud Storage | Request count, bytes transferred |

## Platform metrics versus agent metrics

### Platform or hypervisor metrics

Collected by Google without installing an agent.

Examples:

```text
VM CPU utilization
Disk read/write operations
Network sent/received bytes
```

### Guest OS metrics

Collected from inside the VM, usually by Ops Agent.

Examples:

```text
Memory utilization
Swap usage
Filesystem utilization
Process count
```

### Important exam distinction

A Compute Engine VM can show CPU and network metrics without Ops Agent, but detailed guest-level memory and filesystem metrics usually require an agent.

---

# 5. Custom metrics

Custom metrics are application-specific measurements sent to Cloud Monitoring.

Examples:

```text
Orders processed
Payment failures
Active sessions
Items in business queue
Cache hit ratio
Login attempts
```

Custom metric type names normally begin with:

```text
custom.googleapis.com/
```

Example:

```text
custom.googleapis.com/kubekode/video_processing_queue
```

## When to use custom metrics

Use a custom metric when:

- The application already knows the numeric value.
- The value is not naturally represented by logs.
- You need frequent dashboards or alerts.
- The value represents business or application behavior.

## Example decision

Requirement:

```text
Alert when pending orders exceed 1,000.
```

Best solution:

```text
Application custom metric: pending_orders
```

Less efficient solution:

```text
Write every queue size as a log and convert it into a metric.
```

## Custom metric design advice

Avoid high-cardinality labels.

Bad:

```text
user_id
request_id
session_id
timestamp
```

Better:

```text
environment
region
service
status
```

High-cardinality metrics create many time series and can increase complexity and cost.

---

# 6. Log-based metrics

A log-based metric creates a Monitoring metric from log entries that match a Logging filter.

Cloud Logging includes system-defined log-based metrics and lets you create user-defined metrics. The resulting metrics can be charted and alerted on in Cloud Monitoring. citeturn275060search1turn275060search17

## Example

Suppose an application writes:

```text
Payment failed for transaction
```

Filter:

```text
resource.type="gce_instance"
severity="ERROR"
textPayload:"Payment failed"
```

A counter metric can count matching entries:

```text
payment_failure_count
```

Then Cloud Monitoring can alert when:

```text
payment_failure_count > 10 within 5 minutes
```

## Types of log-based metrics

### Counter metric

Counts matching log entries.

Examples:

- Number of HTTP 500 errors
- Number of failed logins
- Number of application exceptions

### Distribution metric

Extracts numeric values from log fields and creates a distribution.

Example log:

```json
{
  "jsonPayload": {
    "checkout_latency_ms": 742
  }
}
```

The distribution metric can calculate:

- Mean latency
- Percentile latency
- Histogram distribution

## GUI: Create a log-based metric

1. Open **Logging → Logs Explorer**.
2. Write and test the filter.
3. Click **Create metric**.
4. Select:
   - Counter
   - Distribution
5. Enter a metric name and description.
6. Add labels only when necessary.
7. Create the metric.
8. Open Cloud Monitoring to chart or alert on it.

## CLI: Create a counter metric

```bash
gcloud logging metrics create payment_failures \
  --description="Count of payment failure log entries" \
  --log-filter='severity>=ERROR AND textPayload:"Payment failed"'
```

List metrics:

```bash
gcloud logging metrics list
```

Describe:

```bash
gcloud logging metrics describe payment_failures
```

Delete:

```bash
gcloud logging metrics delete payment_failures
```

### ACE exam point

A log-based metric is calculated from **new matching log entries after the metric is created**. It is not generally used to retroactively generate historical metric points from old logs.

---

# 7. Cloud Logging

Cloud Logging is Google Cloud’s real-time log-management system. It provides collection, storage, search, analysis, routing, and integration with Monitoring. Google Cloud services automatically send many platform logs to Cloud Logging. citeturn169747search24

## Common log categories

### Platform logs

Generated by Google Cloud services.

Examples:

- Compute Engine system logs
- GKE control-plane logs
- Cloud Run request logs
- Load balancer logs

### Application logs

Generated by your application.

Example:

```text
Order 1234 successfully processed
```

### Cloud Audit Logs

Record administrative and data-access activities.

Main types:

| Audit log | Purpose |
|---|---|
| Admin Activity | Administrative changes |
| Data Access | Access to user-managed data |
| System Event | Google-initiated administrative action |
| Policy Denied | Request denied by security policy |

### VPC Flow Logs

Capture sampled network flow information for VPC subnets.

### Firewall Rules Logging

Records connections allowed or denied by firewall rules when logging is enabled.

---

# 8. View and filter logs

## Logs Explorer

Logs Explorer is the primary interface for searching and inspecting log entries.

A log entry can contain:

```text
Timestamp
Severity
Log name
Monitored resource
Payload
Labels
Trace ID
Span ID
Insert ID
Source location
```

## Basic filters

### Logs from one VM

```text
resource.type="gce_instance"
resource.labels.instance_name="ace-observability-vm"
```

### Errors only

```text
severity>=ERROR
```

### Logs containing text

```text
textPayload:"connection refused"
```

### Structured JSON field

```text
jsonPayload.status="FAILED"
```

### Cloud Run HTTP 500 responses

```text
resource.type="cloud_run_revision"
httpRequest.status>=500
```

### Logs during a time range

```text
timestamp>="2026-08-01T00:00:00Z"
timestamp<="2026-08-01T02:00:00Z"
```

### Combine conditions

```text
resource.type="gce_instance"
severity>=ERROR
(
  textPayload:"database"
  OR
  textPayload:"timeout"
)
```

### Exclude health checks

```text
resource.type="cloud_run_revision"
-httpRequest.userAgent:"GoogleHC"
```

## GUI: View log details

1. Open **Logging → Logs Explorer**.
2. Select the project.
3. Enter a query.
4. Click **Run query**.
5. Expand a log entry.
6. Inspect:
   - `resource`
   - `logName`
   - `severity`
   - `textPayload` or `jsonPayload`
   - `httpRequest`
   - `labels`
   - `trace`
   - `operation`
7. Use **Show matching entries** for a specific field.
8. Copy the insert ID or trace ID when correlating events.

## CLI: Read logs

Recent error logs:

```bash
gcloud logging read \
  'severity>=ERROR' \
  --limit=20 \
  --order=desc
```

Logs for one VM:

```bash
gcloud logging read \
  'resource.type="gce_instance" AND resource.labels.instance_name="ace-observability-vm"' \
  --limit=50 \
  --order=desc
```

Output selected fields:

```bash
gcloud logging read \
  'severity>=WARNING' \
  --limit=20 \
  --format='table(timestamp,severity,resource.type,textPayload)'
```

Read structured fields:

```bash
gcloud logging read \
  'jsonPayload.status="FAILED"' \
  --format=json \
  --limit=10
```

---

# 9. Log buckets

A log bucket is a Cloud Logging storage container.

Log buckets let you control:

- Storage location
- Retention period
- Access
- Analytics capability
- Centralized log storage

Cloud Logging automatically provides special buckets such as `_Required` and `_Default`. User-created log buckets are created at the project level, while Google creates certain system buckets at higher resource levels. citeturn275060search22turn169747search16

## `_Required` bucket

Stores logs that Google requires to be retained.

Examples include certain audit logs.

Characteristics:

- Cannot be deleted.
- Some required logs cannot be excluded.
- Intended for compliance and administrative visibility.

## `_Default` bucket

Stores logs routed by the default sink.

Characteristics:

- Can receive most normal project logs.
- Retention can be configured.
- Logs can be excluded using sinks.

## User-defined bucket

Used when you need:

- Longer retention
- Regional log storage
- Separate security boundary
- Dedicated application logging
- Centralized organization logs
- Observability Analytics

## Example architecture

```text
Project A logs ─┐
Project B logs ─┼── Central logging project
Project C logs ─┘        ├── security-log-bucket
                         └── application-log-bucket
```

## CLI example

Create a log bucket:

```bash
gcloud logging buckets create application-logs \
  --location=global \
  --retention-days=90 \
  --description="Application logs retained for 90 days"
```

List:

```bash
gcloud logging buckets list --location=global
```

Describe:

```bash
gcloud logging buckets describe application-logs \
  --location=global
```

Update retention:

```bash
gcloud logging buckets update application-logs \
  --location=global \
  --retention-days=180
```

---

# 10. Logs Router

The Logs Router examines incoming log entries and routes them through **sinks**.

A sink contains:

```text
Source
Filter
Destination
Writer identity
```

## Supported destinations

Typical destinations are:

- Cloud Logging bucket
- BigQuery dataset
- Cloud Storage bucket
- Pub/Sub topic

Cloud Logging uses sinks to route matching log entries to supported destinations. citeturn275060search4turn275060search12

## Important behavior

Routing is based on a filter.

Example:

```text
severity>=ERROR
```

Only matching future log entries are routed.

Creating a sink does not usually backfill historical logs.

## Destination choice

| Requirement | Destination |
|---|---|
| Search and retain logs in Logging | Log bucket |
| Run SQL analytics | BigQuery or Observability Analytics |
| Long-term low-cost archive | Cloud Storage |
| Send near-real-time logs to SIEM | Pub/Sub |
| Centralize logs from projects | Log bucket in central project |

## Inclusion and exclusion

An inclusion filter selects logs to route.

Example:

```text
resource.type="gce_instance"
severity>=WARNING
```

An exclusion can reduce unnecessary ingestion.

Example:

```text
resource.type="gce_instance"
severity="INFO"
textPayload:"health check"
```

Be careful: exclusions can permanently prevent certain logs from being stored in a destination.

---

# 11. Observability Analytics and log analytics

Google Cloud documentation now commonly refers to **Observability Analytics** for SQL-based analysis of observability data.

You can:

- Run SQL queries over logs.
- Aggregate large volumes of log data.
- Correlate logs and traces.
- Save and share queries.
- Build dashboard charts.
- Create a linked BigQuery dataset.

A linked BigQuery dataset is a read-only pointer to an analytics-enabled log bucket. It lets BigQuery query the log data without duplicating it into separately stored BigQuery tables. citeturn169747search6turn169747search17turn169747search25

## Logs Explorer versus Observability Analytics

| Logs Explorer | Observability Analytics |
|---|---|
| Logging query language | SQL |
| Best for incident search | Best for aggregation and analysis |
| Inspect individual events | Analyze large datasets |
| Fast troubleshooting | Trends and complex queries |

## Example SQL-style investigation

```sql
SELECT
  severity,
  COUNT(*) AS log_count
FROM
  `PROJECT_ID.LOCATION.BUCKET_ID._AllLogs`
WHERE
  timestamp > TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 1 HOUR)
GROUP BY severity
ORDER BY log_count DESC;
```

The exact table or view name depends on the bucket and analytics configuration.

---

# 12. Export logs to BigQuery

There are two related approaches.

## Approach A: Logging sink to a writable BigQuery dataset

This streams matching logs into BigQuery tables.

Use it when:

- Another team already consumes BigQuery tables.
- You need separate BigQuery storage.
- You need to join exported logs with other business data.
- Existing pipelines depend on physical BigQuery tables.

Logging sends entries in small batches, so you do not need to run a separate load job. citeturn275060search39

## Approach B: Analytics-enabled log bucket plus linked dataset

Google currently recommends this approach for many log-analysis cases because it avoids duplicating storage. The linked dataset is read-only and points to the log bucket. citeturn169747search6turn169747search18

## GUI: Create a BigQuery sink

### Step 1: Create dataset

1. Open **BigQuery**.
2. Select the project.
3. Click **Create dataset**.
4. Dataset ID:

```text
observability_logs
```

5. Select a location.
6. Create the dataset.

### Step 2: Create sink

1. Open **Logging → Log Router**.
2. Click **Create sink**.
3. Sink name:

```text
vm-logs-to-bigquery
```

4. Destination:

```text
BigQuery dataset
```

5. Select:

```text
observability_logs
```

6. Add an inclusion filter:

```text
resource.type="gce_instance"
```

7. Create the sink.

### Step 3: Verify permissions

When created through the console, Google usually helps assign the sink writer identity the required dataset permissions.

The sink service account needs permission to write to the BigQuery dataset.

### Step 4: Generate logs

```bash
logger "ACE BigQuery sink test message"
```

Wait for the log entry to be collected and routed.

### Step 5: Query the exported table

In BigQuery, tables are created based on log names.

Example:

```sql
SELECT
  timestamp,
  severity,
  textPayload
FROM
  `PROJECT_ID.observability_logs.syslog_*`
ORDER BY timestamp DESC
LIMIT 100;
```

## CLI: Create a BigQuery log sink

Set variables:

```bash
export PROJECT_ID="$(gcloud config get-value project)"
export DATASET_ID="observability_logs"
export SINK_NAME="vm-logs-to-bigquery"
export REGION="US"
```

Enable services:

```bash
gcloud services enable \
  logging.googleapis.com \
  bigquery.googleapis.com
```

Create the dataset:

```bash
bq --location="$REGION" mk \
  --dataset \
  "${PROJECT_ID}:${DATASET_ID}"
```

Create the sink:

```bash
gcloud logging sinks create "$SINK_NAME" \
  "bigquery.googleapis.com/projects/${PROJECT_ID}/datasets/${DATASET_ID}" \
  --log-filter='resource.type="gce_instance"' \
  --use-partitioned-tables
```

Get the sink writer identity:

```bash
WRITER_IDENTITY=$(
  gcloud logging sinks describe "$SINK_NAME" \
    --format='value(writerIdentity)'
)

echo "$WRITER_IDENTITY"
```

Grant the writer identity access:

```bash
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="$WRITER_IDENTITY" \
  --role="roles/bigquery.dataEditor"
```

A tighter production design grants access at the dataset level instead of the entire project.

Verify:

```bash
gcloud logging sinks describe "$SINK_NAME"
```

---

# 13. Export logs to an external system

Cloud Logging does not normally send directly to every third-party product.

The common architecture is:

```text
Cloud Logging
   ↓
Logs Router sink
   ↓
Pub/Sub topic
   ↓
Subscriber or connector
   ↓
External SIEM or monitoring platform
```

Examples of external destinations:

- Splunk
- Elastic
- Datadog
- Chronicle or Google Security Operations
- Custom security platform

Google recommends Pub/Sub for near-real-time integration with third-party software. citeturn275060search21turn275060search17

## Example

```text
Audit logs
   ↓
Pub/Sub
   ↓
Dataflow or Cloud Run subscriber
   ↓
External SIEM
```

## CLI example

Create topic:

```bash
gcloud pubsub topics create external-log-export
```

Create sink:

```bash
gcloud logging sinks create external-siem-sink \
  "pubsub.googleapis.com/projects/$PROJECT_ID/topics/external-log-export" \
  --log-filter='logName:"cloudaudit.googleapis.com"'
```

Get writer identity:

```bash
WRITER_IDENTITY=$(
  gcloud logging sinks describe external-siem-sink \
    --format='value(writerIdentity)'
)
```

Grant publisher role:

```bash
gcloud pubsub topics add-iam-policy-binding external-log-export \
  --member="$WRITER_IDENTITY" \
  --role="roles/pubsub.publisher"
```

Create subscription for testing:

```bash
gcloud pubsub subscriptions create external-log-export-sub \
  --topic=external-log-export
```

Pull messages:

```bash
gcloud pubsub subscriptions pull external-log-export-sub \
  --limit=5 \
  --auto-ack
```

---

# 14. Ops Agent

Ops Agent is Google’s recommended agent for collecting logs and metrics from Compute Engine VMs.

It replaces the older separate Monitoring and Logging agents for most workloads.

## What it collects

### Metrics

Examples:

- Memory utilization
- Swap usage
- Filesystem usage
- Process metrics
- Application integration metrics

### Logs

Examples:

- Syslog
- Application files
- Web-server logs
- Database logs
- Structured JSON logs

## Ops Agent architecture

```text
Receivers
   ↓
Processors
   ↓
Pipelines
   ↓
Cloud Logging / Cloud Monitoring
```

### Receivers

Specify where data comes from.

Examples:

```text
files
syslog
hostmetrics
nginx
mysql
prometheus
otlp
```

### Processors

Transform, parse, filter, or modify data.

Examples:

```text
parse_json
parse_regex
exclude_logs
modify_fields
```

### Pipelines

Connect receivers and processors to a destination.

## Install methods

- During VM creation
- Manual installation script
- Agent policies
- Terraform
- Configuration-management tools

The console can install Ops Agent during VM creation, and fleet-wide agent policies can automate installation and maintenance across matching VMs. citeturn169747search4turn169747search8turn169747search9

## Manual installation

On a Debian or Ubuntu VM:

```bash
curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh

sudo bash add-google-cloud-ops-agent-repo.sh --also-install
```

Check service:

```bash
sudo systemctl status google-cloud-ops-agent
```

Restart:

```bash
sudo systemctl restart google-cloud-ops-agent
```

View agent logs:

```bash
sudo journalctl -u google-cloud-ops-agent -n 100
```

## Configuration file

Default Linux path:

```text
/etc/google-cloud-ops-agent/config.yaml
```

Example custom log receiver:

```yaml
logging:
  receivers:
    application_log:
      type: files
      include_paths:
        - /var/log/myapp/*.log

  processors:
    parse_application_json:
      type: parse_json

  service:
    pipelines:
      application_pipeline:
        receivers:
          - application_log
        processors:
          - parse_application_json
```

Validate configuration:

```bash
sudo /opt/google-cloud-ops-agent/bin/google_cloud_ops_agent_engine \
  -in /etc/google-cloud-ops-agent/config.yaml
```

Restart:

```bash
sudo systemctl restart google-cloud-ops-agent
```

## Required VM permissions

The VM service account normally needs permissions equivalent to:

```text
Monitoring Metric Writer
Logs Writer
```

Common roles:

```text
roles/monitoring.metricWriter
roles/logging.logWriter
```

The VM must also have network access to Google APIs.

---

# 15. Managed Service for Prometheus

Google Cloud Managed Service for Prometheus is a fully managed, Prometheus-compatible solution for collecting, storing, querying, and alerting on Prometheus and OpenTelemetry metrics.

It is multi-cloud and cross-project and removes the need to operate the Prometheus storage layer yourself. citeturn275060search0turn275060search9

## Why use it?

Traditional Prometheus requires you to manage:

- Prometheus servers
- Persistent storage
- High availability
- Retention
- Federation
- Scaling
- Cross-cluster querying

Managed Service for Prometheus provides a managed backend while preserving Prometheus conventions.

## Query language

Prometheus metrics can be queried using:

```text
PromQL
```

Example:

```promql
rate(http_requests_total[5m])
```

Error ratio:

```promql
sum(rate(http_requests_total{status=~"5.."}[5m]))
/
sum(rate(http_requests_total[5m]))
```

## Collection options

### GKE managed collection

Google manages collectors running in GKE.

### Self-deployed collection

You deploy collectors yourself.

### Ops Agent collection

Useful for Prometheus endpoints on Compute Engine.

### OpenTelemetry collection

Applications can send OTLP metrics.

## Typical use cases

- GKE workloads already exposing `/metrics`
- Kubernetes applications using Prometheus libraries
- Hybrid or multi-cloud monitoring
- Migrating from self-managed Prometheus
- Centralized cross-cluster observability

---

# 16. Personalized Service Health

Personalized Service Health shows Google Cloud service incidents that are relevant to your projects or organization.

It differs from the public Google Cloud status page because it filters events based on your resources and potential impact. citeturn192360search2turn192360search5turn192360search25

## Information shown

- Active incidents
- Past incidents
- Affected products
- Affected locations
- Event start and end time
- Google updates
- Possible or confirmed project impact

## Public Service Health versus Personalized Service Health

| Public status dashboard | Personalized Service Health |
|---|---|
| Broad public incidents | Project-relevant events |
| General service status | Potential or confirmed project impact |
| Publicly accessible | Requires project access |
| No project context | Uses project and organization context |

## Alerting

You can create alerts for relevant service health events and notify:

- Email
- Pub/Sub
- Webhooks
- Slack
- PagerDuty
- Mobile application

Personalized Service Health provides alert templates directly in its dashboard. citeturn192360search8

## ACE scenario

Question:

```text
An application is failing, but no deployment or configuration change occurred.
How should you check whether the problem is caused by Google Cloud?
```

Best answer:

```text
Check Personalized Service Health and Cloud Hub for active service incidents.
```

---

# 17. Cloud Hub

Cloud Hub provides a centralized overview of the health, performance, optimization, and incidents affecting Google Cloud resources and applications.

It brings together information from:

- Cloud Monitoring
- Personalized Service Health
- Active Assist
- App Hub
- Gemini Cloud Assist
- Resource inventory and health signals

Cloud Hub’s home page summarizes the top health and performance information, active service incidents, Monitoring alerts, metrics, and recommendations. citeturn169747search14turn169747search19

## Main uses

- View open Monitoring alerts.
- View service health incidents.
- View application and workload health.
- Review Active Assist recommendations.
- Start Gemini-assisted investigations.
- Find unhealthy resources from one interface.

## Cloud Hub versus Cloud Monitoring

| Cloud Hub | Cloud Monitoring |
|---|---|
| Consolidated operational overview | Detailed metrics and alerting |
| Combines multiple products | Focuses on time-series monitoring |
| Health, incidents, recommendations | Dashboards, metrics, uptime checks |
| Good starting point | Good deep-dive tool |

---

# 18. Gemini Cloud Assist for Monitoring

Gemini Cloud Assist provides AI assistance for operating and troubleshooting Google Cloud workloads.

For observability, it can help users:

- Explore metrics using natural language.
- Investigate logs.
- Explain alerts and errors.
- Correlate signals.
- Identify likely root causes.
- Create or interpret queries.
- Investigate application and infrastructure problems.

Google’s current documentation describes natural-language exploration across metrics, logs, alerts, and errors. It also supports troubleshooting workflows for services such as Cloud Run, Cloud SQL, AlloyDB, BigQuery, Spanner, and Spark-related services. Some capabilities remain subject to Preview or Pre-GA terms. citeturn169747search15turn169747search35

## Example prompts

```text
Why did latency increase for this Cloud Run service?
```

```text
Show CPU utilization for this VM during the last hour.
```

```text
Find errors related to database connection failures.
```

```text
Explain why this Monitoring alert fired.
```

## Important operational rule

Treat Gemini’s output as an investigation aid, not unquestionable truth.

Always verify recommendations using:

- Metrics
- Logs
- Trace data
- Configuration
- Change history
- Service Health
- Runbooks

---

# Mini Lab: VM → Ops Agent → CPU alert → BigQuery log export

## Architecture

```text
Compute Engine VM
   ├── Host and application logs
   ├── CPU platform metric
   └── Ops Agent guest metrics
            ↓
Cloud Logging and Cloud Monitoring
   ├── CPU alert
   └── Logs Router sink
            ↓
BigQuery dataset
```

---

## Lab prerequisites

```bash
export PROJECT_ID="$(gcloud config get-value project)"
export ZONE="asia-south1-a"
export VM_NAME="ace-observability-vm"
export DATASET_ID="observability_logs"
export SINK_NAME="ace-vm-logs-sink"
```

Enable APIs:

```bash
gcloud services enable \
  compute.googleapis.com \
  monitoring.googleapis.com \
  logging.googleapis.com \
  osconfig.googleapis.com \
  bigquery.googleapis.com
```

---

## Part A: Deploy VM using GUI

1. Open **Compute Engine → VM instances**.
2. Click **Create instance**.
3. Name:

```text
ace-observability-vm
```

4. Region:

```text
asia-south1
```

5. Zone:

```text
asia-south1-a
```

6. Machine type:

```text
e2-medium
```

7. Boot disk:

```text
Debian 12 or supported Ubuntu LTS
```

8. Under Observability, select:

```text
Install Ops Agent for Monitoring and Logging
```

9. Create the VM.

The current console-based installation uses VM Manager and an OS policy to install and maintain Ops Agent. citeturn169747search8

---

## Part B: Deploy VM using CLI

```bash
gcloud compute instances create "$VM_NAME" \
  --zone="$ZONE" \
  --machine-type=e2-medium \
  --image-family=debian-12 \
  --image-project=debian-cloud \
  --service-account="$(gcloud compute project-info describe \
    --format='value(defaultServiceAccount)')" \
  --scopes=https://www.googleapis.com/auth/cloud-platform
```

Install Ops Agent over SSH:

```bash
gcloud compute ssh "$VM_NAME" \
  --zone="$ZONE" \
  --command='
    curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh &&
    sudo bash add-google-cloud-ops-agent-repo.sh --also-install &&
    sudo systemctl status google-cloud-ops-agent --no-pager
  '
```

Generate a log:

```bash
gcloud compute ssh "$VM_NAME" \
  --zone="$ZONE" \
  --command='logger "ACE observability lab test message"'
```

Verify in Logging:

```bash
gcloud logging read \
  'resource.type="gce_instance" AND textPayload:"ACE observability lab test message"' \
  --limit=10 \
  --order=desc
```

---

## Part C: Create CPU alert using GUI

1. Open **Monitoring → Alerting**.
2. Click **Create policy**.
3. Select:
   - Resource: VM Instance
   - Metric: CPU utilization
4. Filter for `ace-observability-vm`.
5. Set threshold:

```text
Above 50%
```

For lab testing, 50% is easier to trigger than 80%.

6. Retest window:

```text
1 minute
```

7. Add an email notification channel.
8. Create the policy.

---

## Part D: Create CPU alert using CLI

Create `lab-cpu-alert.json`:

```bash
cat > lab-cpu-alert.json <<'EOF'
{
  "displayName": "ACE Lab - High VM CPU",
  "combiner": "OR",
  "conditions": [
    {
      "displayName": "CPU above 50 percent",
      "conditionThreshold": {
        "filter": "resource.type=\"gce_instance\" AND metric.type=\"compute.googleapis.com/instance/cpu/utilization\"",
        "comparison": "COMPARISON_GT",
        "thresholdValue": 0.5,
        "duration": "60s",
        "aggregations": [
          {
            "alignmentPeriod": "60s",
            "perSeriesAligner": "ALIGN_MEAN"
          }
        ],
        "trigger": {
          "count": 1
        }
      }
    }
  ],
  "documentation": {
    "content": "CPU is above 50 percent. Check processes and recent workload changes.",
    "mimeType": "text/markdown"
  },
  "enabled": true
}
EOF
```

Create:

```bash
gcloud monitoring policies create \
  --policy-from-file=lab-cpu-alert.json
```

Generate CPU load:

```bash
gcloud compute ssh "$VM_NAME" \
  --zone="$ZONE" \
  --command='
    sudo apt-get update -y &&
    sudo apt-get install -y stress-ng &&
    stress-ng --cpu 2 --timeout 300s
  '
```

Observe:

```text
Monitoring → Alerting → Incidents
```

After the load stops and the metric falls below the threshold, the incident eventually closes.

---

## Part E: Export logs to BigQuery

Create dataset:

```bash
bq --location=US mk \
  --dataset \
  "${PROJECT_ID}:${DATASET_ID}"
```

Create sink:

```bash
gcloud logging sinks create "$SINK_NAME" \
  "bigquery.googleapis.com/projects/${PROJECT_ID}/datasets/${DATASET_ID}" \
  --log-filter='resource.type="gce_instance"' \
  --use-partitioned-tables
```

Get writer identity:

```bash
WRITER_IDENTITY=$(
  gcloud logging sinks describe "$SINK_NAME" \
    --format='value(writerIdentity)'
)

echo "$WRITER_IDENTITY"
```

Grant access:

```bash
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="$WRITER_IDENTITY" \
  --role="roles/bigquery.dataEditor"
```

Generate additional logs:

```bash
gcloud compute ssh "$VM_NAME" \
  --zone="$ZONE" \
  --command='
    logger "ACE BigQuery exported log one"
    logger "ACE BigQuery exported log two"
    logger "ACE BigQuery exported log three"
  '
```

List tables after log delivery:

```bash
bq ls "${PROJECT_ID}:${DATASET_ID}"
```

Query tables in the BigQuery console using the actual created table name:

```sql
SELECT
  timestamp,
  severity,
  textPayload,
  resource.labels.instance_name AS instance_name
FROM
  `PROJECT_ID.observability_logs.TABLE_NAME`
ORDER BY timestamp DESC
LIMIT 100;
```

---

# Phase 19: Diagnostics and Optimization

Phase 18 helps you detect and inspect operational issues. Phase 19 focuses on diagnosing root cause and improving performance, reliability, and cost.

---

# 1. Cloud Trace

Cloud Trace is a distributed tracing system.

It tracks a request as it travels through multiple components.

Example:

```text
User request
   ↓
Load balancer
   ↓
Frontend
   ↓
Order service
   ↓
Payment service
   ↓
Cloud SQL
```

A trace consists of one or more **spans**.

```text
Trace
 ├── Frontend span: 900 ms
 ├── Order service span: 700 ms
 ├── Payment service span: 120 ms
 └── Database span: 520 ms
```

The trace shows that the database call consumed most of the request time.

## Key terms

### Trace

The complete end-to-end journey of one request.

### Span

A timed operation within a trace.

### Parent-child relationship

Spans can contain child spans.

Example:

```text
HTTP request
  └── application handler
       ├── Redis call
       └── Cloud SQL query
```

### Trace ID

Unique identifier connecting all spans of one request.

### Span ID

Unique identifier for one operation.

### Sampling

Only a subset of requests may be traced to control overhead and data volume.

## When to use Cloud Trace

Use Trace when:

- The application uses multiple services.
- Latency is high but CPU is normal.
- You need to find a slow downstream dependency.
- Requests cross Cloud Run, GKE, VMs, databases, or APIs.
- One service appears healthy but the complete request is slow.

Applications generally need instrumentation, commonly through OpenTelemetry or supported tracing libraries. The service account writing trace spans needs appropriate Trace permissions such as the Cloud Trace Agent role. citeturn169747search13turn169747search34

## Trace versus logs

| Trace | Logs |
|---|---|
| Request journey | Individual events |
| Shows timing relationships | Shows detailed messages |
| Finds slow dependency | Finds errors and context |
| Uses trace and span IDs | Uses payload and labels |

Best practice:

```text
Include trace ID in structured logs.
```

This lets operators move between a failed log entry and its distributed trace.

---

# 2. Cloud Profiler

Cloud Profiler continuously collects statistical CPU and memory profiles from production applications.

It helps answer:

```text
Which function is consuming CPU?
Which code path allocates the most memory?
Where is thread contention occurring?
```

Cloud Profiler is designed as a low-overhead production profiler and attributes CPU or memory consumption to application source code. It currently supports profiling for languages and environments including Java, Go, Node.js, Python, Compute Engine, GKE, App Engine flexible, Dataflow, and workloads outside Google Cloud, with support varying by profile type and language. citeturn914778view0

## Common profile types

- CPU time
- Heap
- Allocated heap
- Wall time
- Contention
- Threads

## Flame graph interpretation

A profiler often presents data as a flame graph.

- Width represents resource consumption.
- Wider function blocks consume more CPU or memory.
- Vertical depth represents the call stack.

Example:

```text
processOrder()
   ├── validateOrder()
   ├── calculatePrice()
   └── createInvoice()
          └── generatePDF()   ← very wide
```

Likely optimization target:

```text
generatePDF()
```

## Trace versus Profiler

| Cloud Trace | Cloud Profiler |
|---|---|
| Per-request latency | Aggregate code resource usage |
| Finds slow service or dependency | Finds expensive function |
| Span-based | Code-profile based |
| Request journey | CPU and memory behavior |

### Example

Problem:

```text
P95 latency is high.
```

Trace result:

```text
The application service itself is slow.
```

Profiler result:

```text
JSON serialization consumes 45% of CPU.
```

---

# 3. Query Insights

Query Insights helps detect, diagnose, and prevent query-performance problems in Cloud SQL.

It provides a database-focused view of:

- Query load
- Slow queries
- Query latency
- Database load
- Users
- Databases
- Client addresses
- Tags, when configured
- Wait events, depending on engine and configuration

Google describes Query Insights as a tool for detecting, diagnosing, and preventing Cloud SQL query-performance problems. citeturn275060search32

## Typical investigation

```text
Application latency increased
   ↓
Cloud SQL CPU increased
   ↓
Query Insights shows one query dominates load
   ↓
Query performs full table scan
   ↓
Index advisor recommends an index
```

## Important concepts

### Query fingerprint

Queries with the same structure are grouped together.

These:

```sql
SELECT * FROM orders WHERE order_id = 100;
SELECT * FROM orders WHERE order_id = 200;
```

May share a fingerprint such as:

```sql
SELECT * FROM orders WHERE order_id = ?;
```

This reduces noise and helps identify query patterns.

### Database load

Represents work being performed or waiting in the database.

High database load can be caused by:

- CPU-intensive queries
- Lock contention
- Disk I/O
- Missing indexes
- Too many connections
- Long transactions

## GUI workflow

1. Open **Cloud SQL → Instances**.
2. Select the instance.
3. Open **Query Insights**.
4. Select a time range.
5. Identify the high-load period.
6. Review:
   - Top queries
   - Top databases
   - Top users
   - Client addresses
7. Select a query fingerprint.
8. Inspect latency, execution count, and load.
9. Review the query execution plan where available.
10. Check index recommendations.

---

# 4. Index advisor

Index advisor analyzes database workload and recommends indexes that could improve query performance.

It can help find queries that repeatedly perform:

- Full table scans
- Expensive filtering
- Expensive joins
- Expensive sorting

Google Cloud surfaces index recommendations through supported database products and Query Insights workflows. citeturn275060search14turn275060search24

## Example

Query:

```sql
SELECT *
FROM orders
WHERE customer_id = 500
  AND order_date >= '2026-01-01';
```

Potential index:

```sql
CREATE INDEX idx_orders_customer_date
ON orders(customer_id, order_date);
```

## Do not apply recommendations blindly

An index can improve reads but has trade-offs:

- Additional storage
- Slower inserts
- Slower updates
- Index maintenance
- Possible overlap with existing indexes

Always verify:

```text
Query frequency
Read improvement
Write overhead
Existing indexes
Execution plan
Storage cost
```

---

# 5. Active Assist

Active Assist is a portfolio of tools that generates insights and recommendations to improve Google Cloud environments.

Recommendations can address:

- Cost
- Performance
- Reliability
- Security
- Management
- Sustainability

Google defines Active Assist as a portfolio of recommenders, insights, and analysis tools for optimizing Google Cloud projects. Recommendations can be reviewed through Active Assist, service-specific interfaces, FinOps Hub, Cloud Hub, the CLI, or APIs. citeturn914778view1

## Example recommendations

- Right-size an overprovisioned VM.
- Stop or delete an idle VM.
- Delete an unattached persistent disk.
- Release an unused static IP.
- Remove unused IAM permissions.
- Improve GKE utilization.
- Purchase or optimize committed-use discounts.
- Change a resource configuration for reliability.

## Insight versus recommendation

### Insight

An observation.

Example:

```text
This VM has averaged less than 5% CPU utilization.
```

### Recommendation

A suggested action.

Example:

```text
Change the VM from e2-standard-8 to e2-standard-2.
```

## Recommendation states

A recommendation may be:

- Active
- Claimed
- Succeeded
- Failed
- Dismissed

## Safety rule

Review the business impact before applying recommendations.

Google explicitly advises human review and a rollback plan because blindly applying a recommendation can reduce performance, reliability, or required access. citeturn914778view1

---

# 6. Optimize underused resources

Underused resources increase cost without providing proportional value.

## Compute Engine

Look for:

- Idle VMs
- Overprovisioned machine types
- Unattached persistent disks
- Old snapshots
- Unused static IP addresses
- Unused custom images
- Excessive boot disk size
- Resources running outside business hours

Compute Engine rightsizing recommendations are generated from observed Monitoring metrics. Current documentation states that machine-type recommendations use previous utilization data to recommend a more efficient size. citeturn192360search16

## GKE

Look for:

- Oversized node pools
- Low CPU and memory utilization
- Incorrect Pod requests
- Missing autoscaling
- Unused clusters
- Excessive idle capacity

## Cloud SQL

Look for:

- Oversized instance tiers
- Overallocated storage
- Idle read replicas
- Inefficient queries consuming resources
- Excessive connections

## BigQuery

Look for:

- Repeated full-table scans
- Missing partition filters
- Poor clustering
- Unused reserved capacity
- Materialized-view opportunities

## Storage

Look for:

- Old objects in Standard storage
- No lifecycle rules
- Duplicate backups
- Unnecessary cross-region data
- Old snapshots

## Safe optimization workflow

```text
Review recommendation
   ↓
Validate metrics and workload
   ↓
Check business constraints
   ↓
Create rollback plan
   ↓
Apply in lower environment
   ↓
Monitor
   ↓
Apply to production
```

---

# 7. Investigate an application performance issue

Use a signal-driven workflow.

## Step 1: Confirm the user impact

Check:

- Error rate
- Latency
- Availability
- Affected regions
- Affected versions
- Start time

Questions:

```text
Is the issue global or regional?
Is every user affected?
Did it begin after a deployment?
Is the problem continuous or intermittent?
```

## Step 2: Check Cloud Hub and Service Health

Determine whether:

- Google Cloud has an active incident.
- Monitoring alerts are open.
- A service or workload is unhealthy.
- An Active Assist recommendation is relevant.

Cloud Hub combines Monitoring alerts, health data, service incidents, and recommendations into a central operational view. citeturn169747search14turn169747search28

## Step 3: Check recent changes

Review:

- Deployments
- Configuration changes
- IAM changes
- Network changes
- Database schema changes
- Autoscaling changes
- Feature flags

Use Cloud Audit Logs where appropriate.

## Step 4: Check metrics

Infrastructure:

```text
CPU
Memory
Disk latency
Network traffic
Instance count
Container restarts
```

Application:

```text
Request rate
Error rate
P50/P95/P99 latency
Queue depth
Dependency latency
```

## Step 5: Check logs

Search around the incident start time.

Example:

```text
timestamp>="2026-08-01T03:00:00Z"
severity>=ERROR
```

Look for:

- Exceptions
- Timeouts
- Connection failures
- Permission errors
- Out-of-memory errors
- Rate limiting
- Dependency failures

## Step 6: Check traces

Determine where the request is slow:

```text
Frontend?
Application?
External API?
Database?
Cache?
Queue?
```

## Step 7: Check profiler

When application CPU or memory is high, find the functions causing it.

## Step 8: Check database insights

Use Query Insights and index recommendations for:

- Slow SQL
- Lock contention
- Full table scans
- High database load

## Step 9: Mitigate

Possible actions:

- Roll back deployment.
- Scale out.
- Increase instance size temporarily.
- Disable a feature flag.
- Restart a failed instance.
- Fix an IAM or network rule.
- Add an index after validation.
- Redirect traffic.

## Step 10: Verify and document

Confirm:

- Metrics returned to normal.
- Error rate decreased.
- Latency recovered.
- Alert closed.
- No secondary effects occurred.

Record:

```text
Impact
Timeline
Root cause
Mitigation
Permanent fix
Preventive action
```

---

# 8. Monitor active events and health data

A complete operational view should combine three event sources.

## Application incidents

Examples:

- CPU threshold exceeded
- Error rate increased
- Uptime check failed

Source:

```text
Cloud Monitoring
```

## Google Cloud service incidents

Examples:

- Regional Cloud SQL degradation
- Networking disruption
- API control-plane issue

Source:

```text
Personalized Service Health
```

## Resource optimization findings

Examples:

- Idle VM
- Overprovisioned node pool
- Unused disk
- Excessive IAM role

Source:

```text
Active Assist
```

Cloud Hub can provide a consolidated view across these categories.

---

# Mini Lab: Logs + metrics + trace-style investigation

This lab simulates an application performance problem without requiring full distributed tracing instrumentation.

## Scenario

A simple web application becomes slow and occasionally returns errors.

You need to determine whether the issue is:

- CPU saturation
- Application error
- Database-style delay
- Google Cloud service incident

## Investigation flow

```text
User reports slow application
   ↓
Check alert
   ↓
Check CPU metric
   ↓
Search logs
   ↓
Correlate request ID
   ↓
Identify slow operation
   ↓
Check Service Health
   ↓
Apply fix and verify
```

---

## Step 1: Install a sample application

SSH to the lab VM:

```bash
gcloud compute ssh "$VM_NAME" --zone="$ZONE"
```

Install Python:

```bash
sudo apt-get update
sudo apt-get install -y python3-flask
```

Create application:

```bash
cat > ~/app.py <<'PY'
from flask import Flask, request, jsonify
import logging
import time
import uuid

app = Flask(__name__)
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s severity=%(levelname)s request_id=%(message)s"
)

@app.route("/")
def home():
    request_id = str(uuid.uuid4())
    logging.info(f"{request_id} event=request_started path=/")
    return jsonify(status="healthy", request_id=request_id)

@app.route("/slow")
def slow():
    request_id = str(uuid.uuid4())
    logging.info(f"{request_id} event=request_started path=/slow")

    start = time.time()
    time.sleep(3)
    duration_ms = int((time.time() - start) * 1000)

    logging.warning(
        f"{request_id} event=slow_dependency "
        f"dependency=sample_database duration_ms={duration_ms}"
    )

    return jsonify(
        status="completed",
        request_id=request_id,
        duration_ms=duration_ms
    )

@app.route("/error")
def error():
    request_id = str(uuid.uuid4())
    logging.error(
        f"{request_id} event=request_failed "
        f"error=database_connection_timeout"
    )
    return jsonify(
        status="failed",
        request_id=request_id
    ), 500

app.run(host="0.0.0.0", port=8080)
PY
```

Run the application and write output to a file:

```bash
nohup python3 ~/app.py \
  > ~/sample-app.log \
  2>&1 &
```

Generate traffic:

```bash
for i in {1..10}; do
  curl -s http://localhost:8080/ > /dev/null
done

for i in {1..5}; do
  curl -s http://localhost:8080/slow > /dev/null
done

for i in {1..3}; do
  curl -s http://localhost:8080/error > /dev/null
done
```

---

## Step 2: Configure Ops Agent to collect application logs

Create configuration:

```bash
sudo tee /etc/google-cloud-ops-agent/config.yaml > /dev/null <<'YAML'
logging:
  receivers:
    sample_app:
      type: files
      include_paths:
        - /home/*/sample-app.log

  service:
    pipelines:
      sample_app_pipeline:
        receivers:
          - sample_app
YAML
```

Restart:

```bash
sudo systemctl restart google-cloud-ops-agent
```

Verify:

```bash
sudo systemctl status google-cloud-ops-agent --no-pager
```

---

## Step 3: Find application errors

In Logs Explorer:

```text
resource.type="gce_instance"
textPayload:"event=request_failed"
```

CLI:

```bash
gcloud logging read \
  'resource.type="gce_instance" AND textPayload:"event=request_failed"' \
  --limit=20 \
  --order=desc
```

Expected finding:

```text
error=database_connection_timeout
```

---

## Step 4: Find slow dependencies

Query:

```text
resource.type="gce_instance"
textPayload:"event=slow_dependency"
```

Expected finding:

```text
dependency=sample_database duration_ms=3000
```

This acts like a simple trace-style investigation:

```text
Request
   ↓
Slow dependency
   ↓
3,000 ms duration
```

In a real application, Cloud Trace spans would provide this timing automatically across services.

---

## Step 5: Correlate using request ID

Copy a request ID from a slow or failed log entry.

Search:

```text
resource.type="gce_instance"
textPayload:"REQUEST_ID"
```

This retrieves every log event containing that request ID.

This demonstrates why request or correlation IDs are important in distributed applications.

---

## Step 6: Check metrics

Open:

```text
Monitoring → Metrics Explorer
```

Review:

- VM CPU utilization
- VM memory utilization
- Network traffic
- Process-related metrics where available

Interpretation:

```text
Low CPU + slow response
```

means the likely cause is not CPU saturation. The delay may be I/O, database, network, or dependency related.

```text
High CPU + slow response
```

suggests CPU saturation or expensive application code.

---

## Step 7: Check Service Health

Open:

```text
Cloud Hub → Health
```

and:

```text
Personalized Service Health
```

Verify whether a relevant Google Cloud incident exists.

Possible conclusions:

| Metrics | Logs | Service Health | Likely cause |
|---|---|---|---|
| High CPU | Few errors | Healthy | Resource saturation |
| Normal CPU | Database timeout | Healthy | Application or database issue |
| Normal metrics | Multiple services failing | Active incident | Google Cloud service issue |
| High latency | Slow trace span | Healthy | Downstream dependency |
| High CPU | Expensive function in Profiler | Healthy | Application code issue |

---

# ACE exam decision guide

| Requirement | Best service |
|---|---|
| View CPU or request latency | Cloud Monitoring |
| Alert when CPU is high | Monitoring alert policy |
| Search application errors | Cloud Logging |
| Alert on matching error logs | Log-based metric or log-based alert |
| Retain logs separately | Log bucket |
| Send logs to SIEM | Logs Router → Pub/Sub |
| Analyze logs using SQL | Observability Analytics |
| Join copied log data with business tables | BigQuery sink |
| Collect VM memory and application logs | Ops Agent |
| Monitor Prometheus-instrumented workloads | Managed Service for Prometheus |
| Check Google Cloud outage impact | Personalized Service Health |
| Get a combined operational overview | Cloud Hub |
| Find slow microservice dependency | Cloud Trace |
| Find expensive function in code | Cloud Profiler |
| Diagnose Cloud SQL query load | Query Insights |
| Recommend useful database indexes | Index advisor |
| Find idle or oversized resources | Active Assist |

---

# Important exam traps

## Trap 1: Using Logs Explorer for metrics

Logs Explorer searches events. Metrics Explorer analyzes numeric time-series data.

## Trap 2: Assuming Ops Agent is needed for every VM metric

Compute Engine already provides several platform metrics, including CPU. Ops Agent is needed for detailed guest OS and application telemetry.

## Trap 3: Using BigQuery when a log bucket is enough

For SQL analysis of existing logs, an analytics-enabled log bucket and linked dataset may avoid unnecessary data duplication.

## Trap 4: Exporting historical logs with a new sink

A sink primarily routes new matching log entries. Do not assume it automatically exports all historical entries.

## Trap 5: Sending logs directly to an arbitrary SIEM

The common pattern is:

```text
Cloud Logging → Pub/Sub → external system
```

## Trap 6: Applying rightsizing recommendations blindly

Check workload peaks, seasonality, high-availability requirements, and rollback options first.

## Trap 7: Confusing Trace and Profiler

```text
Trace = where request time is spent.
Profiler = where CPU or memory is spent in code.
```

## Trap 8: Ignoring Google Cloud health events

When multiple unrelated services suddenly fail without a deployment, check Personalized Service Health before making major configuration changes.

## Trap 9: Alerting on every single error

Use thresholds and duration windows to reduce noise.

Better:

```text
More than 10 errors in 5 minutes
```

instead of:

```text
Any single error
```

## Trap 10: High-cardinality custom metric labels

Do not use request IDs or user IDs as metric labels. Keep them in logs and traces instead.
