# Phase 15: Serverless Compute on Google Cloud

Serverless compute allows you to run applications without provisioning or maintaining virtual machines, operating-system patches, Kubernetes clusters, or worker nodes.

In this phase, the main services are:

| Service | Best suited for |
|---|---|
| Cloud Run services | HTTP APIs, web applications, microservices, event receivers |
| Cloud Run jobs | Batch processing and run-to-completion tasks |
| Cloud Run functions | Small, single-purpose, event-driven functions |
| Eventarc | Routing events from Google Cloud services to serverless applications |
| Pub/Sub | Asynchronous messaging and event distribution |
| Cloud Storage events | Triggering processing when files are uploaded, updated, or deleted |

Cloud Run is a fully managed application platform that can run containers, application source code, functions, jobs, and worker-style workloads on Google infrastructure. citeturn792469search1

---

# 1. Understanding serverless computing

In a traditional infrastructure model, you manage:

- Virtual machines
- Operating-system patching
- CPU and memory capacity
- Load balancers
- Instance groups
- Scaling policies
- Application runtimes
- Availability and replacement of failed servers

In a serverless model, Google Cloud manages most of the infrastructure.

You mainly manage:

- Application code
- Container image
- Runtime configuration
- IAM permissions
- Environment variables and secrets
- Scaling limits
- Monitoring
- Application-level security

## Important clarification

Serverless does **not** mean that no servers exist.

It means that:

> The cloud provider manages the servers, while the developer focuses primarily on application code and configuration.

---

# 2. Serverless request flow

A typical serverless application may look like this:

```text
User or application
        |
        v
Cloud Run HTTPS endpoint
        |
        v
Cloud Run container instance
        |
        +----> Cloud SQL
        |
        +----> Firestore
        |
        +----> Cloud Storage
        |
        +----> Pub/Sub
```

An event-driven serverless application may look like this:

```text
File uploaded to Cloud Storage
             |
             v
       Cloud Storage event
             |
             v
          Eventarc
             |
             v
Cloud Run function or Cloud Run service
             |
             v
Resize image / validate file / update database
```

---

# 3. Cloud Run basics

## What is Cloud Run?

Cloud Run is a fully managed serverless platform for running containerized applications.

You can deploy:

- A prebuilt container image
- Application source code
- A web service
- A REST API
- A microservice
- A function
- A batch job
- An event-processing service

Every Cloud Run service receives a stable HTTPS endpoint, usually similar to:

```text
https://SERVICE-NAME-PROJECT-HASH.REGION.run.app
```

Google Cloud manages:

- HTTPS certificates
- Load balancing
- Instance creation
- Autoscaling
- Health management
- Request routing
- Revision management
- Logging integration

Cloud Run applications can be public, private, or accessible only through restricted ingress and IAM configurations. citeturn792469search1

---

## 3.1 Container requirement

A Cloud Run service ultimately runs inside a container.

You have two deployment choices.

### Option 1: Deploy an existing container image

```bash
gcloud run deploy my-service \
  --image=us-central1-docker.pkg.dev/PROJECT_ID/REPOSITORY/app:v1 \
  --region=us-central1
```

This approach is useful when:

- You already have a Dockerfile.
- You are using CI/CD.
- The image is already stored in Artifact Registry.
- You require full control over the runtime and dependencies.

### Option 2: Deploy directly from source code

```bash
gcloud run deploy my-service \
  --source=. \
  --region=us-central1
```

Google Cloud uses buildpacks and Cloud Build to:

1. Examine the source code.
2. Identify the language.
3. Build a container image.
4. Store the image.
5. Deploy the image to Cloud Run.

This is useful for development and simple applications where you do not want to maintain a Dockerfile.

---

## 3.2 Cloud Run container contract

A Cloud Run service must follow certain basic rules.

### Listen on the assigned port

Cloud Run provides the port through the environment variable:

```text
PORT
```

Your application should listen on:

```text
0.0.0.0:$PORT
```

It should not listen only on:

```text
127.0.0.1
```

Example in Node.js:

```javascript
const port = process.env.PORT || 8080;

app.listen(port, "0.0.0.0", () => {
  console.log(`Application listening on port ${port}`);
});
```

### Application should normally be stateless

A container instance can be created or deleted at any time.

Therefore, do not permanently store important application data inside the container filesystem.

Use managed storage such as:

- Cloud SQL
- Firestore
- Spanner
- Cloud Storage
- Memorystore
- Bigtable

Temporary files can be written inside the container, but they may disappear when the instance terminates.

---

## 3.3 Cloud Run service, job, function, and worker pool

### Cloud Run service

A service handles incoming requests.

Examples:

- REST API
- E-commerce backend
- Web application
- Payment webhook receiver
- Mobile application backend
- Event receiver

```text
HTTP request → Cloud Run service → HTTP response
```

### Cloud Run job

A job performs work and exits after completing it.

Examples:

- Database migration
- Daily report generation
- Processing 10,000 files
- Data cleanup
- Batch machine-learning inference

```text
Start job → Perform tasks → Complete → Exit
```

### Cloud Run function

A function is usually a smaller, single-purpose unit of code.

Examples:

- Process an uploaded image
- Send an email after Pub/Sub message arrival
- Validate a file
- Respond to a Firestore event
- Generate thumbnails

### Cloud Run worker pool

A worker pool is designed for continuous, non-HTTP, pull-based workloads such as Kafka, RabbitMQ, and Pub/Sub consumers. Unlike Cloud Run services, worker pools do not automatically scale unless you implement an autoscaling mechanism. citeturn792469search1

For the Associate Cloud Engineer exam, concentrate primarily on:

- Cloud Run services
- Cloud Run jobs
- Cloud Run functions
- Eventarc triggers

---

# 4. Cloud Run execution lifecycle

Consider an API deployed to Cloud Run.

```text
Request arrives
     |
     v
Is an instance available?
     |
     +-- Yes --> Route request to available instance
     |
     +-- No --> Create a new instance
                    |
                    v
             Start container
                    |
                    v
             Handle request
```

When traffic reduces:

```text
Traffic decreases
      |
      v
Idle instances removed
      |
      v
Possibly scale to zero
```

---

# 5. Cold starts

## What is a cold start?

When no instance is running, Cloud Run may need to:

1. Allocate an instance.
2. Start the container.
3. Start the application runtime.
4. Load dependencies.
5. Make the instance ready.
6. Route the request.

The additional startup delay is called a **cold start**.

## Cold-start example

Suppose an internal reporting API receives only a few requests each day.

After a period of inactivity:

```text
Instances = 0
```

When the next request arrives:

```text
Request → New instance created → Application starts → Response
```

That first request may take longer than later requests.

## Reducing cold starts

You can configure minimum instances:

```bash
gcloud run services update ace-api \
  --region=us-central1 \
  --min=1
```

With `min=1`, Cloud Run keeps at least one warm instance available.

### Trade-off

| Minimum instances | Advantage | Disadvantage |
|---|---|---|
| 0 | Lower idle cost | Cold starts possible |
| 1 or more | Faster first response | Idle instances may incur charges |

Cloud Run scales to zero by default when a revision receives no traffic, unless minimum instances or another scaling configuration keeps instances available. citeturn792469search2

---

# 6. Deploying a Cloud Run application

A Cloud Run deployment involves:

```text
Application source or image
             |
             v
       Container image
             |
             v
      Cloud Run service
             |
             v
         Revision
             |
             v
       HTTPS endpoint
```

## Deployment methods

### Google Cloud Console

You can deploy through:

```text
Google Cloud Console
→ Cloud Run
→ Deploy container
```

### Google Cloud CLI

Deploy an image:

```bash
gcloud run deploy SERVICE_NAME \
  --image=IMAGE_URL \
  --region=REGION
```

Deploy source:

```bash
gcloud run deploy SERVICE_NAME \
  --source=. \
  --region=REGION
```

### CI/CD

Cloud Run commonly integrates with:

- Cloud Build
- Artifact Registry
- GitHub Actions
- GitLab CI
- Jenkins
- Terraform

Example:

```text
Developer pushes code
       |
       v
GitHub or Cloud Source Repository
       |
       v
Cloud Build
       |
       v
Artifact Registry
       |
       v
Cloud Run
```

---

# 7. Public versus private Cloud Run services

## Public service

A public Cloud Run service allows unauthenticated access.

CLI option:

```bash
--allow-unauthenticated
```

Example:

```bash
gcloud run deploy public-api \
  --source=. \
  --region=us-central1 \
  --allow-unauthenticated
```

Use cases:

- Public website
- Public product API
- Public webhook endpoint
- Public status page

## Private service

A private service requires an authenticated identity with the appropriate IAM role.

Common role:

```text
roles/run.invoker
```

Use cases:

- Internal microservice
- Payroll API
- Admin API
- Backend service invoked by another service account
- Internal organization application

Example authenticated invocation:

```bash
SERVICE_URL=$(gcloud run services describe private-api \
  --region=us-central1 \
  --format='value(status.url)')

curl -H "Authorization: Bearer $(gcloud auth print-identity-token)" \
  "$SERVICE_URL"
```

---

# 8. Cloud Run revisions

## What is a revision?

A revision is an immutable snapshot of a Cloud Run service configuration.

A new revision is generally created when you change elements such as:

- Container image
- Application code
- Environment variables
- CPU
- Memory
- Concurrency
- Service account
- Minimum or maximum instances
- Startup or liveness probe
- Secrets
- Execution environment

Example:

```text
Service: shopping-api
    |
    +-- shopping-api-00001-abc
    |
    +-- shopping-api-00002-def
    |
    +-- shopping-api-00003-ghi
```

The service name and URL remain stable, while revisions change underneath it.

Cloud Run revisions are immutable. Deploying new code or changing service configuration creates another revision rather than modifying an existing revision in place. citeturn792469search3

---

## 8.1 Why revisions are important

Revisions provide:

- Deployment history
- Safer releases
- Rollbacks
- Canary deployments
- A/B testing
- Traffic splitting
- Testing without production traffic

Example:

```text
Revision v1: Current stable application
Revision v2: New checkout logic
```

You can first send only a small portion of users to v2.

---

## 8.2 Revision naming

Cloud Run can automatically generate revision names:

```text
ace-demo-00001-abc
ace-demo-00002-def
```

You can also specify a revision suffix:

```bash
gcloud run deploy ace-demo \
  --source=. \
  --region=us-central1 \
  --revision-suffix=v2
```

The resulting name may resemble:

```text
ace-demo-v2
```

A clear revision suffix is useful during demonstrations and troubleshooting.

---

## 8.3 Revision tags

A revision tag gives a particular revision a dedicated URL.

Example concept:

```text
https://v2---ace-demo-HASH.REGION.run.app
```

This lets testers access a revision even when it is receiving 0% of normal production traffic.

Use case:

```text
Revision v1 → 100% production traffic
Revision v2 → 0% traffic, but QA tests it through tagged URL
```

---

# 9. Cloud Run traffic splitting

Traffic splitting distributes incoming requests among multiple revisions.

Example:

```text
Users
  |
  v
Cloud Run service URL
  |
  +---- 90% ----> Revision v1
  |
  +---- 10% ----> Revision v2
```

Cloud Run supports gradual rollout, rollback, and routing traffic among multiple revisions. citeturn792469search10

---

## 9.1 Common traffic-splitting strategies

### Blue-green deployment

```text
Blue revision  = current production
Green revision = new release
```

Initially:

```text
Blue  = 100%
Green = 0%
```

After validation:

```text
Blue  = 0%
Green = 100%
```

Use this when you want a quick and controlled switch.

### Canary deployment

Initially:

```text
Revision v1 = 90%
Revision v2 = 10%
```

After successful monitoring:

```text
Revision v1 = 50%
Revision v2 = 50%
```

Finally:

```text
Revision v1 = 0%
Revision v2 = 100%
```

Use this when the new version may introduce risk.

### A/B testing

```text
Revision A = old user-interface design
Revision B = new user-interface design
```

Traffic can be split to compare:

- Conversion rate
- User engagement
- Response time
- Error rate
- Checkout completion

A/B testing requires careful user assignment and analytics. Simple percentage splitting alone may not always guarantee that the same user consistently sees the same application behavior unless session affinity or application-level assignment is implemented.

---

## 9.2 Real-life traffic-splitting example

An e-commerce company introduces a new recommendation algorithm.

### Revision v1

```text
Rule-based recommendations
```

### Revision v2

```text
Machine-learning recommendations
```

Deployment plan:

```text
Day 1: v1=99%, v2=1%
Day 2: v1=90%, v2=10%
Day 3: v1=50%, v2=50%
Day 4: v1=0%,  v2=100%
```

The team monitors:

- HTTP 5xx errors
- Request latency
- CPU utilization
- Conversion rate
- Failed database calls
- Revenue per session

If v2 produces failures:

```text
v1=100%, v2=0%
```

This provides a fast rollback without rebuilding the old application.

---

# 10. Cloud Run autoscaling

Cloud Run automatically adjusts the number of instances according to application demand.

```text
Low traffic   → fewer instances
High traffic  → more instances
No traffic    → possibly zero instances
```

Autoscaling operates at the revision level. Cloud Run uses mechanisms including incoming demand, concurrency, CPU utilization, and revision latency to determine the required capacity. citeturn792469search2

---

## 10.1 Minimum instances

Minimum instances keep some capacity warm.

```bash
gcloud run services update ace-api \
  --region=us-central1 \
  --min=1
```

Use minimum instances when:

- Low latency is important.
- The application takes a long time to start.
- A connection pool must remain ready.
- Traffic arrives unpredictably.
- Cold starts affect the customer experience.

---

## 10.2 Maximum instances

Maximum instances limit scaling.

```bash
gcloud run services update ace-api \
  --region=us-central1 \
  --max=20
```

Use maximum instances to:

- Control costs
- Protect Cloud SQL
- Protect an external API
- Avoid creating too many database connections
- Limit downstream traffic

### Example

Suppose every Cloud Run instance creates ten database connections.

```text
Maximum instances = 100
Connections per instance = 10
Potential connections = 1,000
```

If Cloud SQL supports only 200 safe connections, this configuration could overload the database.

You might instead configure:

```text
Maximum instances = 15
Connections per instance = 10
Maximum expected connections = 150
```

---

## 10.3 Concurrency

Concurrency is the maximum number of requests one container instance can process simultaneously.

Example:

```text
Concurrency = 80
```

A single instance may process up to 80 requests at the same time, depending on application capability.

Cloud Run services created through the console commonly use a default maximum concurrency of 80. citeturn792469search8

### High concurrency

Advantages:

- Fewer instances
- Potentially lower cost
- Better resource utilization

Disadvantages:

- More simultaneous work per container
- Higher memory pressure
- Thread-safety issues
- Slower responses for CPU-intensive applications

### Low concurrency

Advantages:

- Better isolation
- Useful for CPU-intensive workloads
- Lower request contention

Disadvantages:

- More instances may be required
- Potentially higher cost
- Faster pressure on downstream systems

Configure it with:

```bash
gcloud run services update ace-api \
  --region=us-central1 \
  --concurrency=20
```

---

## 10.4 Autoscaling example

Suppose:

```text
Incoming requests = 800 concurrent requests
Maximum concurrency per instance = 80
```

Simplified minimum capacity estimate:

```text
800 ÷ 80 = 10 instances
```

Cloud Run may use approximately ten or more instances depending on:

- CPU utilization
- Request duration
- Instance startup time
- Autoscaler decisions
- Current available capacity
- Traffic pattern

This calculation is conceptual rather than a guarantee of the exact instance count.

---

# 11. Cloud Run resources

Common configurable resources include:

| Configuration | Purpose |
|---|---|
| CPU | Processing capacity |
| Memory | Runtime memory |
| Concurrency | Simultaneous requests per instance |
| Timeout | Maximum request execution time |
| Minimum instances | Warm capacity |
| Maximum instances | Scaling and cost limit |
| Service account | Identity used by application |
| Environment variables | Runtime configuration |
| Secrets | Sensitive values from Secret Manager |
| Ingress | Controls where requests can originate |
| Authentication | Controls who can invoke the service |

Example deployment:

```bash
gcloud run deploy ace-api \
  --source=. \
  --region=us-central1 \
  --cpu=1 \
  --memory=512Mi \
  --concurrency=40 \
  --min=0 \
  --max=10 \
  --timeout=60 \
  --allow-unauthenticated
```

---

# 12. Cloud Run service identity

Every Cloud Run revision uses a service account.

The service account represents the application when it accesses other Google Cloud services.

Example:

```text
Cloud Run service
      |
      | Uses service account
      v
ace-cloud-run-sa@PROJECT_ID.iam.gserviceaccount.com
      |
      +----> Read Cloud Storage
      +----> Publish Pub/Sub messages
      +----> Access Secret Manager
```

Follow least privilege.

Instead of assigning:

```text
roles/editor
```

assign only the required roles, such as:

```text
roles/storage.objectViewer
roles/pubsub.publisher
roles/secretmanager.secretAccessor
```

Deploy with a dedicated service account:

```bash
gcloud run deploy ace-api \
  --source=. \
  --region=us-central1 \
  --service-account=ace-cloud-run-sa@PROJECT_ID.iam.gserviceaccount.com
```

---

# 13. Environment variables and secrets

## Environment variables

Use environment variables for non-sensitive configuration.

```bash
gcloud run services update ace-api \
  --region=us-central1 \
  --set-env-vars=ENVIRONMENT=production,LOG_LEVEL=INFO
```

Examples:

- Environment name
- Feature flag
- API base URL
- Logging level

## Secrets

Do not place passwords or tokens directly in environment variables in deployment scripts.

Store sensitive values in Secret Manager.

Examples:

- Database passwords
- API keys
- OAuth secrets
- Signing keys
- Third-party tokens

A Cloud Run service can consume a secret as:

- An environment variable
- A mounted file

---

# 14. Cloud Run functions

## What are Cloud Run functions?

Cloud Run functions provide a lightweight way to deploy small, single-purpose code that responds to HTTP requests or cloud events.

You write the function, while Google Cloud manages:

- Runtime
- Containerization
- Scaling
- Server infrastructure
- Event integration
- Logging

Cloud Run functions are designed for stand-alone functions that respond to HTTP requests or events without requiring server management. citeturn792469search6

---

## 14.1 Cloud Run service versus Cloud Run function

| Cloud Run service | Cloud Run function |
|---|---|
| Complete application or API | Small, focused function |
| You define the web server and routes | Framework manages invocation pattern |
| Multiple endpoints possible | Usually one logical entry point |
| Full container control | Simplified code-centric deployment |
| Good for microservices | Good for event handlers |
| Can use custom container images | Usually source-and-runtime based |

### Choose Cloud Run service when

- Building a REST API with multiple routes
- Running Spring Boot
- Running Express or FastAPI
- Migrating an existing container
- Requiring custom system packages
- Needing full container control

### Choose Cloud Run function when

- Processing an uploaded file
- Handling a Pub/Sub event
- Sending a notification
- Performing a small transformation
- Responding to one particular event

---

# 15. Event-driven serverless architecture

In a request-driven architecture:

```text
Client → HTTP request → Application
```

In an event-driven architecture:

```text
Something happens → Event generated → Consumer processes event
```

Examples of events:

- A file is uploaded.
- A message is published.
- A database record changes.
- A VM is created.
- An audit log entry is written.
- A scheduled time is reached.
- A new order is placed.

---

## 15.1 Why event-driven design?

Event-driven architectures provide:

- Loose coupling
- Independent scaling
- Asynchronous processing
- Better fault isolation
- Flexible integration
- Easier addition of new consumers

Example:

```text
Order service publishes "OrderCreated"
              |
              v
          Pub/Sub topic
          /      |      \
         v       v       v
  Inventory   Email   Analytics
   service   service    service
```

The order service does not need to call all three downstream services directly.

---

## 15.2 Synchronous versus asynchronous

### Synchronous

```text
Client waits for processing to finish
```

Example:

```text
User → Payment API → Payment result
```

### Asynchronous

```text
Producer sends event and continues
Consumer processes it separately
```

Example:

```text
Order API → Pub/Sub → Email function
```

The order API does not wait for the email to be sent.

---

# 16. Pub/Sub-triggered function

## Architecture

```text
Application
     |
     | Publish message
     v
Pub/Sub topic
     |
     v
Cloud Run function
     |
     v
Process message
```

## Real-life example: order confirmation

An order service publishes:

```json
{
  "orderId": "ORD-1001",
  "customerEmail": "customer@example.com",
  "amount": 149.99
}
```

The function:

1. Receives the message.
2. Decodes the payload.
3. Reads the order details.
4. Sends an email.
5. Logs successful processing.

Other examples:

- Fraud detection
- Log processing
- Notification delivery
- Data transformation
- Analytics updates
- Inventory synchronization

---

## 16.1 Delivery and idempotency

Event systems may deliver an event more than once.

Therefore, functions should be idempotent whenever possible.

Idempotent means:

> Processing the same event multiple times produces the same final result as processing it once.

### Bad design

```text
Receive event → Always charge customer's card
```

If the event is delivered twice, the customer might be charged twice.

### Better design

```text
Receive event
   |
Check event ID in database
   |
   +-- Already processed → Stop
   |
   +-- Not processed → Process and store event ID
```

---

# 17. Cloud Storage object event trigger

A Cloud Storage event can be generated when an object is:

- Created or finalized
- Deleted
- Archived
- Metadata-updated

A common event type is:

```text
google.cloud.storage.object.v1.finalized
```

This event generally means an object has been successfully created or overwritten.

---

## 17.1 Real-life image-processing scenario

```text
User uploads profile.jpg
          |
          v
Cloud Storage bucket
          |
          v
Object finalized event
          |
          v
Eventarc
          |
          v
Cloud Run function
          |
          +----> Validate image
          +----> Resize image
          +----> Create thumbnail
          +----> Store result
```

Other use cases:

- Virus scanning
- CSV validation
- PDF metadata extraction
- Video transcoding
- Thumbnail generation
- Document classification
- Moving validated files to another bucket
- Loading CSV data into BigQuery

Cloud Run functions can respond to Cloud Storage, Pub/Sub, Firestore, and other Google Cloud events. citeturn792469search26

---

# 18. Eventarc basics

## What is Eventarc?

Eventarc is a managed event-routing service.

It routes events from event producers to destinations.

```text
Event producer
      |
      v
Eventarc trigger
      |
      v
Event destination
```

Eventarc manages parts of:

- Event routing
- Event filtering
- Authentication
- Delivery
- Observability
- Error handling

Eventarc supports both Standard and Advanced editions. Eventarc Standard is suitable for straightforward event delivery, while Eventarc Advanced supports more complex routing, transformation, and governance scenarios. citeturn792469search0

---

## 18.1 Eventarc terminology

### Event provider

The service that produces the event.

Examples:

- Cloud Storage
- Pub/Sub
- Firestore
- Cloud Audit Logs
- Custom application

### Event

A state change or occurrence.

Example:

```text
A new object was created in a bucket.
```

### Trigger

A trigger defines:

- Which events to listen for
- Which filters to apply
- Which destination should receive the event
- Which service account should be used

### Destination

The service that receives the event.

Examples:

- Cloud Run service
- Cloud Run function
- Workflows
- GKE destination in supported configurations

---

## 18.2 Eventarc filtering

An Eventarc trigger can filter events using attributes such as:

```text
type
bucket
serviceName
methodName
resourceName
```

Example:

```text
type = google.cloud.storage.object.v1.finalized
bucket = ace-upload-bucket
```

Only object-finalized events from the specified bucket are routed to the destination.

---

## 18.3 CloudEvents

Eventarc commonly delivers events using the CloudEvents specification.

A CloudEvent contains metadata such as:

```text
id
source
type
subject
time
specversion
```

Conceptual example:

```json
{
  "id": "123456789",
  "source": "//storage.googleapis.com/projects/_/buckets/ace-upload-bucket",
  "type": "google.cloud.storage.object.v1.finalized",
  "subject": "objects/report.csv",
  "time": "2026-07-26T08:00:00Z"
}
```

---

# 19. Eventarc Standard versus Advanced

## Eventarc Standard

Best for straightforward routing:

```text
Cloud Storage event → Cloud Run
Pub/Sub message → Cloud Run
Audit log event → Workflow
```

Choose Standard when:

- Routing is relatively simple.
- There is one event source and destination.
- Basic filtering is sufficient.
- You need a standard Google Cloud event trigger.

## Eventarc Advanced

Better suited to complex event topologies involving:

- Multiple sources
- Multiple destinations
- Event buses
- Message transformation
- Centralized event governance
- More sophisticated routing

For most introductory ACE labs, Eventarc Standard is sufficient.

---

# 20. Practical service-selection scenarios

## Scenario 1: Host a Spring Boot API

Requirement:

```text
Run a containerized Spring Boot application with multiple REST endpoints.
```

Best choice:

```text
Cloud Run service
```

Why:

- Complete web application
- Container support
- Automatic HTTPS
- Autoscaling
- Custom runtime dependencies

---

## Scenario 2: Generate thumbnails after upload

Requirement:

```text
When an image is uploaded, create a thumbnail.
```

Best choice:

```text
Cloud Run function + Cloud Storage trigger
```

Why:

- Event-driven
- Small, focused logic
- No public endpoint required
- Automatic scaling

---

## Scenario 3: Process 100,000 independent files

Requirement:

```text
Process a large batch and finish.
```

Best choice:

```text
Cloud Run job
```

Why:

- Work runs to completion
- Supports parallel tasks
- Does not need an HTTP endpoint

---

## Scenario 4: Process order messages asynchronously

Requirement:

```text
Process every order placed by an application.
```

Best choice:

```text
Pub/Sub + Cloud Run function
```

or:

```text
Pub/Sub push subscription + Cloud Run service
```

---

## Scenario 5: Run a Kafka consumer continuously

Requirement:

```text
Continuously pull and process Kafka records.
```

Possible choice:

```text
Cloud Run worker pool
```

A standard request-driven Cloud Run service is not the natural model for a continuously running pull consumer.

---

# 21. Mini Lab 1: Deploy Cloud Run app and split traffic 90/10

## Lab architecture

```text
Browser
   |
   v
Cloud Run service
   |
   +---- 90% ----> Revision v1
   |
   +---- 10% ----> Revision v2
```

## Lab objectives

You will:

1. Enable the required APIs.
2. Create a simple application.
3. Deploy revision v1.
4. Deploy revision v2 without production traffic.
5. Split traffic 90/10.
6. Test both revisions.
7. Roll back to v1.

---

## 21.1 Set environment variables

Open Cloud Shell.

```bash
export PROJECT_ID=$(gcloud config get-value project)
export REGION=us-central1
export SERVICE_NAME=ace-serverless-demo

echo "Project: $PROJECT_ID"
echo "Region: $REGION"
```

Set the project explicitly when required:

```bash
gcloud config set project "$PROJECT_ID"
```

---

## 21.2 Enable APIs

```bash
gcloud services enable \
  run.googleapis.com \
  cloudbuild.googleapis.com \
  artifactregistry.googleapis.com
```

Verify:

```bash
gcloud services list --enabled \
  --filter="NAME:(run.googleapis.com cloudbuild.googleapis.com artifactregistry.googleapis.com)"
```

---

## 21.3 Create the application

```bash
mkdir -p ~/ace-serverless-demo
cd ~/ace-serverless-demo
```

Create `package.json`:

```bash
cat > package.json <<'EOF'
{
  "name": "ace-serverless-demo",
  "version": "1.0.0",
  "description": "Cloud Run revision and traffic splitting demo",
  "main": "index.js",
  "scripts": {
    "start": "node index.js"
  },
  "engines": {
    "node": ">=20"
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
  res.status(200).json({
    message: "Welcome to the ACE Cloud Run lab",
    version: version,
    revision: process.env.K_REVISION || "local",
    service: process.env.K_SERVICE || "local",
    timestamp: new Date().toISOString()
  });
});

app.get("/health", (req, res) => {
  res.status(200).json({
    status: "healthy",
    version: version
  });
});

app.listen(port, "0.0.0.0", () => {
  console.log(`Server started on port ${port}, version=${version}`);
});
EOF
```

Review the files:

```bash
cat package.json
cat index.js
```

---

## 21.4 Deploy revision v1 using CLI

```bash
gcloud run deploy "$SERVICE_NAME" \
  --source=. \
  --region="$REGION" \
  --allow-unauthenticated \
  --set-env-vars=APP_VERSION=v1 \
  --revision-suffix=v1 \
  --cpu=1 \
  --memory=512Mi \
  --concurrency=80 \
  --min=0 \
  --max=10
```

Get the service URL:

```bash
export SERVICE_URL=$(gcloud run services describe "$SERVICE_NAME" \
  --region="$REGION" \
  --format='value(status.url)')

echo "$SERVICE_URL"
```

Test it:

```bash
curl "$SERVICE_URL"
```

Expected output:

```json
{
  "message": "Welcome to the ACE Cloud Run lab",
  "version": "v1",
  "revision": "ace-serverless-demo-v1"
}
```

---

## 21.5 Deploy revision v1 through the GUI

The equivalent GUI process is:

1. Open **Google Cloud Console**.
2. Go to **Cloud Run**.
3. Select **Deploy container**.
4. Choose **Service**.
5. Select **Deploy one revision from an existing container image** or deploy from source when that option is available.
6. Enter the service name:

```text
ace-serverless-demo
```

7. Select the region:

```text
us-central1
```

8. Under authentication, choose:

```text
Allow unauthenticated invocations
```

9. Open **Containers, Volumes, Networking, Security**.
10. Configure:
    - CPU: `1`
    - Memory: `512 MiB`
    - Maximum instances: `10`
    - Concurrency: `80`
11. Add environment variable:

```text
APP_VERSION = v1
```

12. Deploy the service.
13. Open the generated service URL.
14. Verify that the response shows `v1`.

The exact console labels can change, but the concepts remain service name, region, authentication, container configuration, variables, and scaling.

---

## 21.6 Deploy revision v2 without traffic

You do not need to modify the source because the application reads the version from an environment variable.

Deploy v2:

```bash
gcloud run deploy "$SERVICE_NAME" \
  --source=. \
  --region="$REGION" \
  --set-env-vars=APP_VERSION=v2 \
  --revision-suffix=v2 \
  --no-traffic
```

The `--no-traffic` option prevents normal production traffic from immediately moving to v2.

List revisions:

```bash
gcloud run revisions list \
  --service="$SERVICE_NAME" \
  --region="$REGION"
```

Example:

```text
REVISION                         ACTIVE  SERVICE
ace-serverless-demo-v2          no      ace-serverless-demo
ace-serverless-demo-v1          yes     ace-serverless-demo
```

---

## 21.7 Deploy revision v2 through the GUI

1. Open **Cloud Run**.
2. Select `ace-serverless-demo`.
3. Click **Edit and deploy new revision**.
4. Change the environment variable:

```text
APP_VERSION = v2
```

5. Find the traffic option.
6. Select the option that prevents the new revision from immediately receiving production traffic, such as:

```text
Serve this revision immediately: disabled
```

or deploy it and later adjust traffic manually.

7. Deploy.
8. Open the **Revisions** tab.
9. Confirm that both v1 and v2 are listed.

---

## 21.8 Split traffic 90/10 through CLI

Confirm the exact revision names:

```bash
gcloud run revisions list \
  --service="$SERVICE_NAME" \
  --region="$REGION" \
  --format="table(metadata.name,status.conditions[0].status)"
```

Set variables:

```bash
export REVISION_V1="${SERVICE_NAME}-v1"
export REVISION_V2="${SERVICE_NAME}-v2"
```

Apply the split:

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

Expected concept:

```yaml
traffic:
- percent: 90
  revisionName: ace-serverless-demo-v1
- percent: 10
  revisionName: ace-serverless-demo-v2
```

---

## 21.9 Split traffic through the GUI

1. Open **Cloud Run**.
2. Select `ace-serverless-demo`.
3. Open the **Revisions** tab.
4. Click **Manage traffic**.
5. Assign:

```text
ace-serverless-demo-v1 = 90%
ace-serverless-demo-v2 = 10%
```

6. Ensure the total is exactly `100%`.
7. Save the traffic configuration.
8. Review the traffic allocation table.

---

## 21.10 Test traffic splitting

Run multiple requests:

```bash
for i in $(seq 1 30); do
  curl -s "$SERVICE_URL"
  echo
done
```

You should see mostly:

```json
"version": "v1"
```

and occasionally:

```json
"version": "v2"
```

With only a small number of requests, the observed ratio may not be exactly 90/10. Over a larger number of independent requests, the distribution should become more representative.

---

## 21.11 Test revision v2 directly with a tag

You can assign a tag during traffic management.

Example:

```bash
gcloud run services update-traffic "$SERVICE_NAME" \
  --region="$REGION" \
  --set-tags="${REVISION_V2}=test-v2"
```

Describe the service:

```bash
gcloud run services describe "$SERVICE_NAME" \
  --region="$REGION" \
  --format="yaml(status.traffic)"
```

Use the tagged URL shown in the output to test v2 directly.

This is useful when v2 has:

```text
0% production traffic
```

but QA engineers still need to access it.

---

## 21.12 Promote v2 to 100%

```bash
gcloud run services update-traffic "$SERVICE_NAME" \
  --region="$REGION" \
  --to-revisions="${REVISION_V2}=100"
```

Alternatively, route traffic to the latest revision:

```bash
gcloud run services update-traffic "$SERVICE_NAME" \
  --region="$REGION" \
  --to-latest
```

Use `--to-latest` carefully because “latest” means the most recently deployed revision, which may not always be the revision you intend to promote.

---

## 21.13 Roll back to v1

```bash
gcloud run services update-traffic "$SERVICE_NAME" \
  --region="$REGION" \
  --to-revisions="${REVISION_V1}=100"
```

No image rebuild is required because v1 already exists.

---

# 22. Mini Lab 2: Pub/Sub-triggered Cloud Run function

## Architecture

```text
gcloud pubsub topics publish
            |
            v
       Pub/Sub topic
            |
            v
Cloud Run function
            |
            v
       Cloud Logging
```

---

## 22.1 Enable APIs

```bash
gcloud services enable \
  cloudfunctions.googleapis.com \
  run.googleapis.com \
  cloudbuild.googleapis.com \
  artifactregistry.googleapis.com \
  pubsub.googleapis.com \
  eventarc.googleapis.com \
  logging.googleapis.com
```

---

## 22.2 Create Pub/Sub topic

```bash
export TOPIC_NAME=ace-serverless-events

gcloud pubsub topics create "$TOPIC_NAME"
```

Verify:

```bash
gcloud pubsub topics list \
  --filter="name:$TOPIC_NAME"
```

---

## 22.3 Create function source

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
import logging

import functions_framework


@functions_framework.cloud_event
def pubsub_handler(cloud_event):
    event_id = cloud_event["id"]
    event_type = cloud_event["type"]

    message = cloud_event.data.get("message", {})
    encoded_data = message.get("data", "")

    decoded_text = (
        base64.b64decode(encoded_data).decode("utf-8")
        if encoded_data
        else ""
    )

    attributes = message.get("attributes", {})

    try:
        parsed_data = json.loads(decoded_text)
    except json.JSONDecodeError:
        parsed_data = decoded_text

    logging.info(
        "Processed Pub/Sub event",
        extra={
            "event_id": event_id,
            "event_type": event_type,
            "payload": parsed_data,
            "attributes": attributes,
        },
    )

    print(
        json.dumps(
            {
                "event_id": event_id,
                "event_type": event_type,
                "payload": parsed_data,
                "attributes": attributes,
            }
        )
    )
EOF
```

---

## 22.4 Deploy function using CLI

```bash
export FUNCTION_NAME=ace-pubsub-function

gcloud functions deploy "$FUNCTION_NAME" \
  --gen2 \
  --runtime=python312 \
  --region="$REGION" \
  --source=. \
  --entry-point=pubsub_handler \
  --trigger-topic="$TOPIC_NAME" \
  --memory=256Mi \
  --timeout=60s \
  --max-instances=5
```

List functions:

```bash
gcloud functions list \
  --regions="$REGION"
```

Describe the function:

```bash
gcloud functions describe "$FUNCTION_NAME" \
  --gen2 \
  --region="$REGION"
```

---

## 22.5 Deploy through the GUI

1. Open **Cloud Run** or **Cloud Run functions** in the console.
2. Click **Write a function** or **Create function**.
3. Enter:

```text
Function name: ace-pubsub-function
Region: us-central1
Runtime: Python 3.12
```

4. Choose an event trigger.
5. Select:

```text
Pub/Sub
```

6. Choose the topic:

```text
ace-serverless-events
```

7. Set the entry point:

```text
pubsub_handler
```

8. Add the Python code to `main.py`.
9. Add the dependency to `requirements.txt`.
10. Configure:
    - Memory: `256 MiB`
    - Timeout: `60 seconds`
    - Maximum instances: `5`
11. Deploy.

The console may create and manage the underlying Eventarc and Pub/Sub resources automatically.

---

## 22.6 Publish a test message

```bash
gcloud pubsub topics publish "$TOPIC_NAME" \
  --message='{"orderId":"ORD-1001","status":"CREATED","amount":149.99}' \
  --attribute=source=ace-lab,environment=dev
```

Expected command response:

```text
messageIds:
- '1234567890123456'
```

---

## 22.7 Review logs

```bash
gcloud functions logs read "$FUNCTION_NAME" \
  --gen2 \
  --region="$REGION" \
  --limit=20
```

Alternatively:

```bash
gcloud logging read \
  "resource.type=cloud_run_revision AND resource.labels.service_name:${FUNCTION_NAME}" \
  --limit=20 \
  --format=json
```

GUI:

1. Open the function.
2. Select **Logs**.
3. Look for the decoded order message.
4. Confirm that the function executed after the Pub/Sub publish operation.

---

# 23. Mini Lab 3: Cloud Storage-triggered function

## Architecture

```text
Upload file
    |
    v
Cloud Storage bucket
    |
    v
Object finalized event
    |
    v
Eventarc trigger
    |
    v
Cloud Run function
    |
    v
Cloud Logging
```

---

## 23.1 Create a unique bucket

Bucket names must be globally unique.

```bash
export BUCKET_NAME="${PROJECT_ID}-ace-upload-$RANDOM"

gcloud storage buckets create "gs://${BUCKET_NAME}" \
  --location="$REGION" \
  --uniform-bucket-level-access
```

Verify:

```bash
gcloud storage buckets describe "gs://${BUCKET_NAME}"
```

---

## 23.2 Create function source

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
import json
import logging

import functions_framework


@functions_framework.cloud_event
def process_storage_file(cloud_event):
    data = cloud_event.data

    bucket = data.get("bucket")
    file_name = data.get("name")
    content_type = data.get("contentType")
    size = data.get("size")
    generation = data.get("generation")

    result = {
        "event_id": cloud_event["id"],
        "event_type": cloud_event["type"],
        "bucket": bucket,
        "file_name": file_name,
        "content_type": content_type,
        "size": size,
        "generation": generation,
    }

    logging.info("Cloud Storage object processed", extra=result)
    print(json.dumps(result))
EOF
```

---

## 23.3 Deploy using CLI

```bash
export STORAGE_FUNCTION_NAME=ace-storage-function

gcloud functions deploy "$STORAGE_FUNCTION_NAME" \
  --gen2 \
  --runtime=python312 \
  --region="$REGION" \
  --source=. \
  --entry-point=process_storage_file \
  --trigger-bucket="$BUCKET_NAME" \
  --memory=256Mi \
  --timeout=60s \
  --max-instances=5
```

The deployment creates or configures an event trigger so object events from the bucket can invoke the function.

---

## 23.4 Deploy through the GUI

1. Open **Cloud Run functions**.
2. Click **Create function**.
3. Enter:

```text
Name: ace-storage-function
Region: us-central1
Runtime: Python 3.12
```

4. Under trigger type, choose:

```text
Cloud Storage
```

5. Select event type:

```text
Object finalized
```

6. Select the bucket.
7. Set the entry point:

```text
process_storage_file
```

8. Add the source code and dependency.
9. Deploy the function.

Keep the function, trigger, and bucket in compatible locations. Regional alignment simplifies the lab and avoids location-related trigger errors.

---

## 23.5 Upload a test object

```bash
echo "ACE Cloud Run Functions Lab" > sample.txt

gcloud storage cp sample.txt "gs://${BUCKET_NAME}/incoming/sample.txt"
```

List objects:

```bash
gcloud storage ls "gs://${BUCKET_NAME}/incoming/"
```

---

## 23.6 Check logs

```bash
gcloud functions logs read "$STORAGE_FUNCTION_NAME" \
  --gen2 \
  --region="$REGION" \
  --limit=20
```

Expected information:

```json
{
  "event_type": "google.cloud.storage.object.v1.finalized",
  "bucket": "PROJECT_ID-ace-upload-12345",
  "file_name": "incoming/sample.txt",
  "content_type": "text/plain"
}
```

---

# 24. Monitoring and troubleshooting

## Cloud Logging

Anything written to standard output or standard error is collected by Cloud Logging.

Examples:

```javascript
console.log("Order processed");
console.error("Database connection failed");
```

Python:

```python
print("File processed")
logging.error("Processing failed")
```

---

## Important Cloud Run metrics

Monitor:

- Request count
- Request latency
- HTTP response codes
- Container instance count
- CPU utilization
- Memory utilization
- Maximum concurrent requests
- Startup latency
- Billable instance time

During a canary deployment, compare v1 and v2 by:

- Revision name
- Error rate
- p95 latency
- Instance count
- CPU and memory use

---

## Common error: container failed to start

Possible causes:

- Application did not listen on `$PORT`.
- Application listened only on localhost.
- Startup took too long.
- A dependency is missing.
- The application crashed.
- The Dockerfile start command is incorrect.

Check logs:

```bash
gcloud run services logs read "$SERVICE_NAME" \
  --region="$REGION" \
  --limit=50
```

---

## Common error: permission denied

Possible causes:

- Caller lacks `roles/run.invoker`.
- Cloud Run service account lacks permission.
- Eventarc service account lacks invocation permission.
- Pub/Sub service agent permissions are missing.
- User cannot act as the selected service account.

Inspect IAM policy:

```bash
gcloud run services get-iam-policy "$SERVICE_NAME" \
  --region="$REGION"
```

---

## Common error: Pub/Sub function does not trigger

Check:

```bash
gcloud pubsub topics describe "$TOPIC_NAME"
```

Then inspect the function:

```bash
gcloud functions describe "$FUNCTION_NAME" \
  --gen2 \
  --region="$REGION"
```

Check Eventarc:

```bash
gcloud eventarc triggers list \
  --location="$REGION"
```

Review logs:

```bash
gcloud functions logs read "$FUNCTION_NAME" \
  --gen2 \
  --region="$REGION" \
  --limit=50
```

---

## Common error: Storage trigger does not execute

Verify:

- The upload completed successfully.
- The configured event is object finalized.
- The trigger references the correct bucket.
- The function and trigger use compatible regions.
- Eventarc APIs are enabled.
- The trigger service account has correct permissions.
- The event is not being filtered incorrectly.

List triggers:

```bash
gcloud eventarc triggers list \
  --location="$REGION"
```

---

# 25. Security best practices

## Use a dedicated service account

Do not rely on an overly privileged default service account for production applications.

```bash
gcloud iam service-accounts create ace-run-sa \
  --display-name="ACE Cloud Run Service Account"
```

Assign only the required role:

```bash
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:ace-run-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/storage.objectViewer"
```

---

## Keep internal services private

Do not select `--allow-unauthenticated` unless public access is actually required.

For service-to-service communication:

1. Keep the destination private.
2. Grant the caller service account `roles/run.invoker`.
3. Send an identity token with the request.

---

## Protect secrets

Use Secret Manager instead of:

- Committing credentials
- Hard-coding passwords
- Storing API keys in source code
- Placing sensitive values directly in public deployment scripts

---

## Restrict ingress

Cloud Run ingress options can be used to restrict whether traffic may arrive from:

- The public internet
- Internal Google Cloud sources
- Internal networking and load-balancing paths

IAM answers **who may invoke** the service, while ingress settings help control **where requests may originate**.

---

# 26. Cost considerations

Cloud Run cost is influenced by:

- CPU allocation
- Memory allocation
- Request execution time
- Number of instances
- Minimum instances
- Request count
- Networking
- Build and image-storage activity
- Logging volume

## Cost-optimization practices

- Allow scale-to-zero for infrequently used services.
- Avoid unnecessarily high memory.
- Use suitable concurrency.
- Set maximum instances.
- Remove unnecessary minimum instances.
- Keep containers small.
- Reduce startup time.
- Avoid excessive logs.
- Use regional services near dependencies.
- Protect databases from excessive scaling.

---

# 27. ACE exam-focused points

Remember these distinctions:

### Cloud Run

Use when you need:

- A managed container platform
- HTTP endpoints
- Automatic scaling
- Revision-based deployments
- Traffic splitting
- Custom application runtimes
- No cluster management

### Cloud Run functions

Use when you need:

- Small event handlers
- Pub/Sub triggers
- Cloud Storage triggers
- HTTP-triggered functions
- Minimal infrastructure management

### Eventarc

Use when you need:

- Managed event routing
- Filtering by event type or attributes
- Routing Google Cloud events to Cloud Run or functions
- Event-driven architecture without custom polling

### Pub/Sub

Use when you need:

- Asynchronous messaging
- Producer-consumer decoupling
- Fan-out
- Buffering
- Event distribution

---

# 28. Sample ACE-style questions

## Question 1

A company has deployed a new version of its API to Cloud Run. It wants only 10% of users to access the new version initially.

What should it do?

A. Create a new Compute Engine instance  
B. Configure a 90/10 traffic split between Cloud Run revisions  
C. Create another VPC  
D. Increase Cloud Run concurrency  

**Answer: B**

Traffic splitting supports controlled canary deployment.

---

## Question 2

A company needs to execute code whenever a new image is uploaded to a Cloud Storage bucket.

What is the most appropriate solution?

A. Continuously poll the bucket from a VM  
B. Run a permanent GKE Pod  
C. Create a Cloud Run function with a Cloud Storage object-finalized trigger  
D. Schedule a Cloud SQL query  

**Answer: C**

The requirement is event-driven and can be handled without permanent infrastructure.

---

## Question 3

A Cloud Run API must protect Cloud SQL from receiving too many concurrent connections.

What should you configure?

A. Only minimum instances  
B. Maximum Cloud Run instances and appropriate connection pooling  
C. More revisions  
D. Public unauthenticated access  

**Answer: B**

Maximum instances place an upper limit on the number of Cloud Run instances that can connect to the database.

---

## Question 4

A Cloud Run application should remain private and be invoked only by another Google Cloud service account.

What should you do?

A. Allow unauthenticated access  
B. Grant the calling service account `roles/run.invoker`  
C. Grant the calling account Project Owner  
D. Assign an external IP  

**Answer: B**

Cloud Run invocation should be controlled with IAM and least privilege.

---

## Question 5

An application receives very infrequent requests, and the company wants to minimize idle compute cost.

Which configuration is most appropriate?

A. Set minimum instances to 10  
B. Set minimum instances to 0  
C. Use a fixed managed instance group  
D. Disable autoscaling  

**Answer: B**

Allowing scale-to-zero reduces idle resource use, although the first request may experience a cold start.

---

# 29. Cleanup

Delete the Cloud Run service:

```bash
gcloud run services delete "$SERVICE_NAME" \
  --region="$REGION" \
  --quiet
```

Delete functions:

```bash
gcloud functions delete "$FUNCTION_NAME" \
  --gen2 \
  --region="$REGION" \
  --quiet

gcloud functions delete "$STORAGE_FUNCTION_NAME" \
  --gen2 \
  --region="$REGION" \
  --quiet
```

Delete the Pub/Sub topic:

```bash
gcloud pubsub topics delete "$TOPIC_NAME" \
  --quiet
```

Delete the bucket and its contents:

```bash
gcloud storage rm --recursive "gs://${BUCKET_NAME}"
```

Review remaining Eventarc triggers:

```bash
gcloud eventarc triggers list \
  --location="$REGION"
```

---

# 30. Final revision summary

```text
Cloud Run
├── Runs containers and source-deployed applications
├── Provides HTTPS endpoints
├── Automatically scales
├── Can scale to zero
├── Supports minimum and maximum instances
├── Supports concurrency
├── Creates immutable revisions
├── Supports traffic splitting and rollback
└── Uses service accounts for Google Cloud access

Cloud Run functions
├── Runs focused functions
├── Supports HTTP triggers
├── Supports Pub/Sub events
├── Supports Cloud Storage events
├── Automatically scales
└── Integrates with Eventarc

Eventarc
├── Receives events
├── Filters events
├── Routes events
├── Authenticates delivery
└── Connects event producers to destinations
```

The key mini-lab flow is:

```text
Deploy v1
   ↓
Deploy v2 with no traffic
   ↓
Confirm two revisions
   ↓
Route 90% to v1
   ↓
Route 10% to v2
   ↓
Monitor errors and latency
   ↓
Promote v2 or roll back to v1
```
