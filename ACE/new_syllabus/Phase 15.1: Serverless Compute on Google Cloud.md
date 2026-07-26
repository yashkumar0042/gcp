

# Phase 15: Serverless Compute on Google Cloud

Serverless computing allows you to run applications without managing virtual machines, operating-system patches, Kubernetes worker nodes, or manual scaling.

Google Cloud manages the infrastructure, while you mainly manage:

* Application code
* Container images
* IAM permissions
* Environment variables and secrets
* Scaling configuration
* Monitoring and logging

Serverless does not mean that servers do not exist. It means Google manages the servers for you.

---

# 1. Cloud Run Basics

## What is Cloud Run?

Cloud Run is a fully managed serverless platform used to run containerized applications.

It is commonly used for:

* REST APIs
* Web applications
* Microservices
* Mobile backends
* Webhooks
* Event-processing services
* Internal business applications

Example architecture:

```text
User
  |
  v
Cloud Run HTTPS URL
  |
  v
Containerized application
  |
  +---- Cloud SQL
  +---- Firestore
  +---- Pub/Sub
  +---- Cloud Storage
```

Cloud Run automatically provides:

* HTTPS endpoint
* TLS certificate
* Load balancing
* Autoscaling
* Health management
* Logging
* Revision management

---

## Cloud Run application requirements

A Cloud Run application must listen on the port provided by:

```text
PORT
```

The application should listen on:

```text
0.0.0.0:$PORT
```

Example Node.js code:

```javascript
const port = process.env.PORT || 8080;

app.listen(port, "0.0.0.0", () => {
  console.log(`Application started on port ${port}`);
});
```

Cloud Run applications should normally be stateless.

Do not permanently store business data inside the container filesystem because the container can be terminated at any time.

Use:

* Cloud Storage for files
* Cloud SQL for relational data
* Firestore for document data
* Memorystore for caching
* BigQuery for analytics

---

# 2. Cloud Run Deployment Methods

You can deploy Cloud Run applications in two main ways.

## Deploy a container image

Use this when the image already exists in Artifact Registry.

```bash
gcloud run deploy my-api \
  --image=us-central1-docker.pkg.dev/PROJECT_ID/app-repo/my-api:v1 \
  --region=us-central1
```

This gives you full control over:

* Dockerfile
* Runtime
* Dependencies
* Operating-system packages
* Image version

## Deploy directly from source

```bash
gcloud run deploy my-api \
  --source=. \
  --region=us-central1
```

Google Cloud automatically:

1. Detects the programming language.
2. Builds the application.
3. Creates a container image.
4. Stores the image.
5. Deploys it to Cloud Run.

Source deployment is useful for simple development and labs.

---

# 3. Public and Private Cloud Run Services

## Public Cloud Run service

A public service allows unauthenticated users to access the application.

```bash
gcloud run deploy public-api \
  --source=. \
  --region=us-central1 \
  --allow-unauthenticated
```

Use cases:

* Public website
* Public REST API
* Public webhook
* Product landing page

## Private Cloud Run service

A private service requires an authenticated identity.

Common IAM role:

```text
roles/run.invoker
```

Use cases:

* Internal microservice
* Employee application
* Admin API
* Backend-to-backend communication

Authenticated request example:

```bash
SERVICE_URL=$(gcloud run services describe private-api \
  --region=us-central1 \
  --format='value(status.url)')

curl \
  -H "Authorization: Bearer $(gcloud auth print-identity-token)" \
  "$SERVICE_URL"
```

---

# 4. Cloud Run Revisions

A revision is an immutable version of a Cloud Run service.

A new revision is created when you change:

* Container image
* Application code
* Environment variables
* CPU or memory
* Concurrency
* Service account
* Minimum or maximum instances
* Secrets
* Timeout settings

Example:

```text
Service: payment-api

payment-api-v1
payment-api-v2
payment-api-v3
```

The service URL remains the same, but traffic can be routed to different revisions.

## Why revisions are useful

Revisions support:

* Deployment history
* Rollback
* Canary deployment
* Blue-green deployment
* Traffic splitting
* Testing new versions

Example:

```text
Revision v1 = current stable application
Revision v2 = new application version
```

You can send only 10% of traffic to v2 before a full rollout.

---

# 5. Cloud Run Traffic Splitting

Traffic splitting allows requests to be divided between multiple revisions.

Example:

```text
Cloud Run service URL
        |
        +---- 90% ---- Revision v1
        |
        +---- 10% ---- Revision v2
```

## Canary deployment

A canary deployment gradually introduces a new version.

Example rollout:

```text
Step 1: v1 = 90%, v2 = 10%
Step 2: v1 = 50%, v2 = 50%
Step 3: v1 = 0%,  v2 = 100%
```

Monitor:

* Error rate
* HTTP 5xx responses
* Request latency
* CPU usage
* Memory usage
* Business failures

If v2 has problems:

```text
v1 = 100%
v2 = 0%
```

This rollback does not require rebuilding the old application.

## Real-life example

An e-commerce company deploys a new checkout version.

```text
Revision v1 = existing checkout
Revision v2 = new checkout
```

Initially:

```text
v1 = 90%
v2 = 10%
```

The company checks:

* Payment failures
* Checkout completion rate
* Response time
* Error logs

If results are good, v2 receives 100% traffic.

---

# 6. Cloud Run Autoscaling

Cloud Run automatically increases or decreases instances based on incoming requests.

```text
More traffic → More instances
Less traffic → Fewer instances
No traffic → Possibly zero instances
```

## Minimum instances

Minimum instances keep containers ready even when there is no traffic.

```bash
gcloud run services update my-api \
  --region=us-central1 \
  --min=1
```

Use minimum instances when:

* Low latency is important.
* Cold starts affect users.
* Application startup takes time.
* Requests arrive unpredictably.

Trade-off:

```text
min=0 → lower idle cost, possible cold start
min=1 → faster response, some idle cost
```

## Maximum instances

Maximum instances limit how far the application can scale.

```bash
gcloud run services update my-api \
  --region=us-central1 \
  --max=20
```

Use maximum instances to:

* Control cost
* Protect Cloud SQL
* Protect external APIs
* Limit database connections
* Prevent downstream overload

Example:

```text
Each Cloud Run instance opens 10 DB connections.
Maximum instances = 20.

Maximum expected DB connections = 200.
```

## Concurrency

Concurrency defines how many requests one container instance can process at the same time.

```bash
gcloud run services update my-api \
  --region=us-central1 \
  --concurrency=40
```

High concurrency:

* Uses fewer instances
* Can reduce cost
* May increase CPU and memory pressure

Low concurrency:

* Better isolation
* Useful for CPU-heavy workloads
* May create more instances

---

# 7. Cold Starts

A cold start occurs when Cloud Run must create a new container instance before handling a request.

Process:

```text
Request arrives
   |
No instance available
   |
Create instance
   |
Start container
   |
Handle request
```

Cold starts are more noticeable when:

* Minimum instances are zero.
* The application has many dependencies.
* The container image is large.
* Startup code is slow.

Ways to reduce cold starts:

* Configure minimum instances.
* Reduce application startup time.
* Use smaller images.
* Avoid unnecessary dependencies.

---

# 8. Cloud Run Functions

Cloud Run functions are used for small, focused pieces of code that run in response to HTTP requests or events.

Common use cases:

* Send notification after an event
* Process Pub/Sub messages
* Resize uploaded images
* Validate CSV files
* Update a database
* Process Cloud Storage events

## Cloud Run service versus Cloud Run function

| Cloud Run service                      | Cloud Run function          |
| -------------------------------------- | --------------------------- |
| Complete web application               | Small focused function      |
| Multiple routes possible               | Usually one entry point     |
| Full container control                 | Simplified deployment       |
| Good for Spring Boot, Express, FastAPI | Good for event handlers     |
| Best for APIs and microservices        | Best for event-driven tasks |

Choose Cloud Run service for:

* Spring Boot API
* Web application
* Multiple REST endpoints
* Custom Docker container

Choose Cloud Run function for:

* Pub/Sub message processing
* File upload processing
* Small automation
* Notification handler

---

# 9. Event-Driven Serverless

In event-driven architecture, an application reacts when something happens.

Examples:

* A Pub/Sub message is published.
* A file is uploaded.
* A database record changes.
* An audit log event occurs.
* A new order is created.

Architecture:

```text
Event producer
      |
      v
Event generated
      |
      v
Eventarc or Pub/Sub
      |
      v
Cloud Run service or function
```

Benefits:

* Loose coupling
* Independent scaling
* Asynchronous processing
* Better fault isolation
* Easy integration between services

---

# 10. Pub/Sub-Triggered Function

Architecture:

```text
Application
    |
Publish message
    |
    v
Pub/Sub topic
    |
    v
Cloud Run function
    |
    v
Process message
```

## Real-life scenario

An order service publishes this event:

```json
{
  "orderId": "ORD-1001",
  "customerEmail": "user@example.com",
  "status": "CREATED"
}
```

A Cloud Run function receives the event and:

1. Reads the message.
2. Retrieves order details.
3. Sends an email.
4. Updates analytics.
5. Writes logs.

Other examples:

* Fraud detection
* Inventory updates
* Notification delivery
* Log processing
* Data transformation

## Idempotency

Pub/Sub may deliver a message more than once.

Applications should therefore be idempotent.

Bad design:

```text
Every message delivery → Charge customer
```

Better design:

```text
Receive event
   |
Check event ID
   |
Already processed? → Stop
   |
Not processed → Perform action and save event ID
```

---

# 11. Cloud Storage Object Event Trigger

Cloud Storage can generate events when an object is:

* Created
* Overwritten
* Deleted
* Archived
* Metadata-updated

A common event is:

```text
google.cloud.storage.object.v1.finalized
```

It normally means a file has been successfully created or overwritten.

## Real-life scenario

```text
User uploads image
      |
Cloud Storage bucket
      |
Object finalized event
      |
Eventarc
      |
Cloud Run function
      |
Create thumbnail
```

Other use cases:

* Virus scanning
* CSV validation
* PDF text extraction
* Image resizing
* Video processing
* Loading data into BigQuery
* Moving files between buckets

---

# 12. Eventarc Basics

Eventarc is a managed event-routing service.

It connects an event producer to an event destination.

```text
Event producer
      |
Eventarc trigger
      |
Cloud Run service or function
```

## Eventarc components

### Event provider

The service that creates the event.

Examples:

* Cloud Storage
* Pub/Sub
* Firestore
* Cloud Audit Logs

### Trigger

The trigger defines:

* Which event to listen for
* Event filters
* Destination service
* Service account

### Destination

The application that receives the event.

Examples:

* Cloud Run service
* Cloud Run function
* Workflows

## Event filtering example

```text
Event type:
google.cloud.storage.object.v1.finalized

Bucket:
ace-upload-bucket
```

Only upload or overwrite events from that bucket are delivered.

---

# Lab 1: Deploy Cloud Run App and Split Traffic 90/10

## Lab objective

You will:

1. Deploy revision v1.
2. Deploy revision v2.
3. Keep v2 from immediately receiving traffic.
4. Split traffic 90/10.
5. Test the deployment.
6. Roll back if required.

---

## CLI Lab

### Step 1: Set variables

```bash
export PROJECT_ID=$(gcloud config get-value project)
export REGION=us-central1
export SERVICE_NAME=ace-cloud-run-demo
```

### Step 2: Enable APIs

```bash
gcloud services enable \
  run.googleapis.com \
  cloudbuild.googleapis.com \
  artifactregistry.googleapis.com
```

### Step 3: Create application

```bash
mkdir -p ~/ace-cloud-run-demo
cd ~/ace-cloud-run-demo
```

Create `package.json`:

```bash
cat > package.json <<'EOF'
{
  "name": "ace-cloud-run-demo",
  "version": "1.0.0",
  "main": "index.js",
  "scripts": {
    "start": "node index.js"
  },
  "dependencies": {
    "express": "^4.21.2"
  }
}
EOF
```

Create `index.js`:

```bash
cat > index.js <<'EOF'
const express = require("express");

const app = express();
const port = process.env.PORT || 8080;
const version = process.env.APP_VERSION || "unknown";

app.get("/", (req, res) => {
  res.json({
    message: "Cloud Run ACE Lab",
    version: version,
    revision: process.env.K_REVISION || "local"
  });
});

app.listen(port, "0.0.0.0", () => {
  console.log(`Application running on port ${port}`);
});
EOF
```

### Step 4: Deploy revision v1

```bash
gcloud run deploy "$SERVICE_NAME" \
  --source=. \
  --region="$REGION" \
  --allow-unauthenticated \
  --set-env-vars=APP_VERSION=v1 \
  --revision-suffix=v1 \
  --cpu=1 \
  --memory=512Mi \
  --min=0 \
  --max=10
```

Get URL:

```bash
export SERVICE_URL=$(gcloud run services describe "$SERVICE_NAME" \
  --region="$REGION" \
  --format='value(status.url)')

echo "$SERVICE_URL"
```

Test:

```bash
curl "$SERVICE_URL"
```

Expected result:

```json
{
  "message": "Cloud Run ACE Lab",
  "version": "v1",
  "revision": "ace-cloud-run-demo-v1"
}
```

### Step 5: Deploy revision v2 with no traffic

```bash
gcloud run deploy "$SERVICE_NAME" \
  --source=. \
  --region="$REGION" \
  --set-env-vars=APP_VERSION=v2 \
  --revision-suffix=v2 \
  --no-traffic
```

List revisions:

```bash
gcloud run revisions list \
  --service="$SERVICE_NAME" \
  --region="$REGION"
```

### Step 6: Split traffic 90/10

```bash
export REVISION_V1="${SERVICE_NAME}-v1"
export REVISION_V2="${SERVICE_NAME}-v2"
```

```bash
gcloud run services update-traffic "$SERVICE_NAME" \
  --region="$REGION" \
  --to-revisions="${REVISION_V1}=90,${REVISION_V2}=10"
```

Verify:

```bash
gcloud run services describe "$SERVICE_NAME" \
  --region="$REGION" \
  --format="yaml(status.traffic)"
```

### Step 7: Test traffic

```bash
for i in $(seq 1 30); do
  curl -s "$SERVICE_URL"
  echo
done
```

Most responses should show:

```text
version: v1
```

A smaller number should show:

```text
version: v2
```

The result may not be exactly 90/10 with only a few requests.

### Step 8: Promote v2

```bash
gcloud run services update-traffic "$SERVICE_NAME" \
  --region="$REGION" \
  --to-revisions="${REVISION_V2}=100"
```

### Step 9: Roll back to v1

```bash
gcloud run services update-traffic "$SERVICE_NAME" \
  --region="$REGION" \
  --to-revisions="${REVISION_V1}=100"
```

---

## GUI Lab

### Deploy revision v1

1. Open Google Cloud Console.
2. Go to **Cloud Run**.
3. Click **Deploy container**.
4. Select **Service**.
5. Enter the service name:

```text
ace-cloud-run-demo
```

6. Select region:

```text
us-central1
```

7. Choose **Allow unauthenticated invocations**.
8. Configure:

   * CPU: `1`
   * Memory: `512 MiB`
   * Minimum instances: `0`
   * Maximum instances: `10`
9. Add environment variable:

```text
APP_VERSION = v1
```

10. Deploy the service.
11. Open the generated URL and verify version `v1`.

### Deploy revision v2

1. Open the deployed Cloud Run service.
2. Click **Edit and deploy new revision**.
3. Change:

```text
APP_VERSION = v2
```

4. Configure the deployment so the new revision does not immediately receive all traffic.
5. Deploy.
6. Open the **Revisions** tab.
7. Confirm that v1 and v2 exist.

### Split traffic

1. Open the Cloud Run service.
2. Select **Manage traffic**.
3. Configure:

```text
Revision v1 = 90%
Revision v2 = 10%
```

4. Save the configuration.
5. Refresh the service URL several times.
6. Check Cloud Logging and metrics for both revisions.

---

# Lab 2: Pub/Sub-Triggered Function

## CLI Lab

### Step 1: Enable APIs

```bash
gcloud services enable \
  cloudfunctions.googleapis.com \
  run.googleapis.com \
  cloudbuild.googleapis.com \
  artifactregistry.googleapis.com \
  pubsub.googleapis.com \
  eventarc.googleapis.com
```

### Step 2: Create topic

```bash
export TOPIC_NAME=ace-order-events

gcloud pubsub topics create "$TOPIC_NAME"
```

### Step 3: Create function code

```bash
mkdir -p ~/pubsub-function
cd ~/pubsub-function
```

Create `requirements.txt`:

```bash
cat > requirements.txt <<'EOF'
functions-framework>=3.0.0,<4.0.0
EOF
```

Create `main.py`:

```bash
cat > main.py <<'EOF'
import base64
import json
import functions_framework


@functions_framework.cloud_event
def process_order(cloud_event):
    message = cloud_event.data.get("message", {})
    encoded_data = message.get("data", "")

    decoded_data = (
        base64.b64decode(encoded_data).decode("utf-8")
        if encoded_data
        else ""
    )

    try:
        payload = json.loads(decoded_data)
    except json.JSONDecodeError:
        payload = decoded_data

    print({
        "event_id": cloud_event["id"],
        "payload": payload
    })
EOF
```

### Step 4: Deploy function

```bash
export FUNCTION_NAME=ace-order-function

gcloud functions deploy "$FUNCTION_NAME" \
  --gen2 \
  --runtime=python312 \
  --region="$REGION" \
  --source=. \
  --entry-point=process_order \
  --trigger-topic="$TOPIC_NAME" \
  --memory=256Mi \
  --timeout=60s \
  --max-instances=5
```

### Step 5: Publish message

```bash
gcloud pubsub topics publish "$TOPIC_NAME" \
  --message='{"orderId":"ORD-1001","status":"CREATED"}'
```

### Step 6: Check logs

```bash
gcloud functions logs read "$FUNCTION_NAME" \
  --gen2 \
  --region="$REGION" \
  --limit=20
```

---

## GUI Lab

1. Open **Cloud Run functions**.
2. Click **Create function**.
3. Enter:

   * Name: `ace-order-function`
   * Region: `us-central1`
   * Runtime: Python 3.12
4. Select trigger type: **Pub/Sub**.
5. Select topic:

```text
ace-order-events
```

6. Set entry point:

```text
process_order
```

7. Add the Python code and requirements.
8. Set:

   * Memory: `256 MiB`
   * Timeout: `60 seconds`
   * Maximum instances: `5`
9. Deploy.
10. Publish a message from the Pub/Sub console.
11. Open function logs and verify the message was processed.

---

# Lab 3: Cloud Storage Object Trigger

## CLI Lab

### Step 1: Create bucket

```bash
export BUCKET_NAME="${PROJECT_ID}-ace-upload-$RANDOM"

gcloud storage buckets create "gs://${BUCKET_NAME}" \
  --location="$REGION" \
  --uniform-bucket-level-access
```

### Step 2: Create function code

```bash
mkdir -p ~/storage-function
cd ~/storage-function
```

Create `requirements.txt`:

```bash
cat > requirements.txt <<'EOF'
functions-framework>=3.0.0,<4.0.0
EOF
```

Create `main.py`:

```bash
cat > main.py <<'EOF'
import functions_framework


@functions_framework.cloud_event
def process_file(cloud_event):
    data = cloud_event.data

    print({
        "bucket": data.get("bucket"),
        "file": data.get("name"),
        "content_type": data.get("contentType"),
        "size": data.get("size")
    })
EOF
```

### Step 3: Deploy function

```bash
export STORAGE_FUNCTION=ace-storage-function

gcloud functions deploy "$STORAGE_FUNCTION" \
  --gen2 \
  --runtime=python312 \
  --region="$REGION" \
  --source=. \
  --entry-point=process_file \
  --trigger-bucket="$BUCKET_NAME" \
  --memory=256Mi \
  --timeout=60s
```

### Step 4: Upload test file

```bash
echo "Cloud Storage event test" > sample.txt

gcloud storage cp sample.txt \
  "gs://${BUCKET_NAME}/incoming/sample.txt"
```

### Step 5: Check logs

```bash
gcloud functions logs read "$STORAGE_FUNCTION" \
  --gen2 \
  --region="$REGION" \
  --limit=20
```

---

## GUI Lab

1. Open **Cloud Run functions**.
2. Click **Create function**.
3. Enter:

   * Name: `ace-storage-function`
   * Region: `us-central1`
   * Runtime: Python 3.12
4. Choose trigger: **Cloud Storage**.
5. Select event type:

```text
Object finalized
```

6. Select the bucket.
7. Set entry point:

```text
process_file
```

8. Add the function code.
9. Deploy.
10. Open Cloud Storage.
11. Upload a test file.
12. Open function logs and verify the event.

---

# Monitoring and Troubleshooting

## View Cloud Run logs

```bash
gcloud run services logs read "$SERVICE_NAME" \
  --region="$REGION" \
  --limit=50
```

## View revisions

```bash
gcloud run revisions list \
  --service="$SERVICE_NAME" \
  --region="$REGION"
```

## View Eventarc triggers

```bash
gcloud eventarc triggers list \
  --location="$REGION"
```

## Common Cloud Run errors

### Container failed to start

Possible causes:

* Application is not listening on `$PORT`.
* Application listens only on `localhost`.
* Required dependency is missing.
* Application crashes during startup.
* Start command is incorrect.

### Permission denied

Possible causes:

* Caller lacks `roles/run.invoker`.
* Service account lacks required IAM permissions.
* User cannot deploy using the selected service account.

### Function not triggering

Check:

* Correct Pub/Sub topic
* Correct Cloud Storage bucket
* Correct event type
* Eventarc trigger
* Region compatibility
* IAM permissions
* Function logs

---

# ACE Exam Summary

Remember:

## Cloud Run

Choose Cloud Run for:

* Containerized APIs
* Web applications
* Microservices
* Automatic scaling
* HTTPS endpoint
* Revisions
* Traffic splitting

## Cloud Run functions

Choose functions for:

* Small event handlers
* Pub/Sub triggers
* Cloud Storage triggers
* Lightweight automation

## Eventarc

Choose Eventarc for:

* Event routing
* Event filtering
* Connecting Google Cloud events to Cloud Run
* Event-driven applications

## Pub/Sub

Choose Pub/Sub for:

* Asynchronous messaging
* Decoupling services
* Event distribution
* Buffering workloads

Core lab flow:

```text
Deploy v1
   |
Deploy v2 without traffic
   |
Split traffic 90/10
   |
Monitor revisions
   |
Promote v2 or roll back to v1
```

This version removes secondary topics while retaining the important ACE theory and executable GUI/CLI labs.
