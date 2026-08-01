# Phase 12–14: Containers, Artifact Registry, and GKE

These phases cover the complete flow:

```text
Application source code
        ↓
Dockerfile
        ↓
Container image
        ↓
Artifact Registry
        ↓
GKE Deployment
        ↓
Pods
        ↓
Kubernetes Service
        ↓
Users / applications
```

---

# Phase 12: Containers and Artifact Registry

## 1. Docker basics

Docker is a platform for packaging and running applications inside **containers**.

A container includes:

- Application code
- Runtime, such as Java, Python, or Node.js
- Application dependencies
- Required operating-system libraries
- Configuration needed to start the application

Containers share the host operating system’s kernel, unlike virtual machines, which normally run a complete guest operating system.

## Container versus virtual machine

| Feature | Container | Virtual machine |
|---|---|---|
| Isolation | Process-level | Hardware-level |
| Operating system | Shares host kernel | Separate guest OS |
| Startup time | Usually seconds | Usually minutes |
| Size | Typically MBs | Typically GBs |
| Portability | Very high | Moderate |
| Resource overhead | Low | Higher |
| Common GCP service | GKE, Cloud Run | Compute Engine |

### ACE exam point

Use:

- **Compute Engine VM** when you need full operating-system control.
- **GKE** when managing multiple containerized applications.
- **Cloud Run** when you want serverless container execution without managing Kubernetes.
- **Artifact Registry** to centrally store container images and software packages.

---

## 2. Important Docker terms

### Dockerfile

A text file containing instructions used to build a container image.

Example:

```dockerfile
FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8080

CMD ["python", "app.py"]
```

### Explanation

| Instruction | Purpose |
|---|---|
| `FROM` | Selects the base image |
| `WORKDIR` | Defines the working directory |
| `COPY` | Copies files into the image |
| `RUN` | Executes commands during image creation |
| `EXPOSE` | Documents the application port |
| `ENV` | Defines environment variables |
| `CMD` | Default command executed when the container starts |
| `ENTRYPOINT` | Defines the main executable |
| `.dockerignore` | Prevents unnecessary files from being included |

### `RUN` versus `CMD`

- `RUN` executes while the image is being built.
- `CMD` executes when a container is started.

```dockerfile
RUN pip install flask
CMD ["python", "app.py"]
```

### `COPY` versus `ADD`

Prefer `COPY` for normal file copying.

`ADD` supports additional functionality such as extracting local archives, but its implicit behavior can make builds less predictable.

---

## 3. Docker image

A **container image** is a read-only package containing the application and everything required to run it.

An image consists of multiple layers.

Example:

```text
python:3.12-slim          Base layer
pip install flask         Dependency layer
COPY application code     Application layer
```

When a Dockerfile instruction changes, Docker generally rebuilds that instruction and the layers after it.

### Image versus container

| Image | Container |
|---|---|
| Read-only template | Running instance of an image |
| Built using `docker build` | Started using `docker run` |
| Stored in a registry | Runs on a host |
| Can be versioned using tags | Has a runtime lifecycle |

### Example

```bash
docker build -t hello-app:v1 .
docker run -d -p 8080:8080 hello-app:v1
```

Here:

- `hello-app:v1` is the image.
- The running process is the container.
- Host port `8080` maps to container port `8080`.

---

## 4. Common Docker commands

```bash
# Display Docker version
docker version

# Build an image
docker build -t hello-app:v1 .

# List local images
docker images

# Run a container
docker run -d --name hello-container -p 8080:8080 hello-app:v1

# List running containers
docker ps

# List all containers
docker ps -a

# View container logs
docker logs hello-container

# Execute a command inside the container
docker exec -it hello-container sh

# Stop a container
docker stop hello-container

# Remove a container
docker rm hello-container

# Remove an image
docker rmi hello-app:v1

# Tag an image
docker tag hello-app:v1 LOCATION-docker.pkg.dev/PROJECT_ID/REPOSITORY/hello-app:v1

# Push an image
docker push LOCATION-docker.pkg.dev/PROJECT_ID/REPOSITORY/hello-app:v1

# Pull an image
docker pull LOCATION-docker.pkg.dev/PROJECT_ID/REPOSITORY/hello-app:v1
```

---

## 5. Container image best practices

### Use small base images

Instead of:

```dockerfile
FROM python:3.12
```

Consider:

```dockerfile
FROM python:3.12-slim
```

Smaller images:

- Download faster
- Start faster
- Have a smaller attack surface
- Consume less storage

### Use specific image versions

Avoid relying only on:

```dockerfile
FROM python:latest
```

Prefer:

```dockerfile
FROM python:3.12-slim
```

For highly controlled environments, use an image digest:

```dockerfile
FROM python@sha256:IMAGE_DIGEST
```

### Run as a non-root user

```dockerfile
RUN useradd --create-home appuser
USER appuser
```

### Do not put secrets in images

Do not write:

```dockerfile
ENV DATABASE_PASSWORD=my-secret-password
```

Use instead:

- Secret Manager
- Kubernetes Secrets
- Workload Identity Federation
- Environment-specific configuration

### Use multi-stage builds

Example for a Java application:

```dockerfile
FROM eclipse-temurin:21-jdk AS builder

WORKDIR /app
COPY . .
RUN ./gradlew clean bootJar

FROM eclipse-temurin:21-jre

WORKDIR /app
COPY --from=builder /app/build/libs/*.jar app.jar

EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

The first stage builds the application. The final stage contains only the runtime and packaged application.

---

# 6. Artifact Registry

Artifact Registry is Google Cloud’s managed service for storing, managing, and securing software artifacts.

It supports formats including:

- Docker container images
- Helm charts
- Maven packages
- npm packages
- Python packages
- Apt packages
- Yum packages
- Generic artifacts

Container images are packages containing the software and runtime elements required to run an application. Artifact Registry organizes these images inside explicitly created repositories. citeturn986975search29

## Artifact Registry hierarchy

```text
Google Cloud project
└── Location
    └── Repository
        └── Image
            └── Tag or digest
```

Example image URL:

```text
asia-south1-docker.pkg.dev/my-project/ace-repository/hello-app:v1
```

Components:

| Component | Example |
|---|---|
| Repository location | `asia-south1` |
| Repository hostname | `asia-south1-docker.pkg.dev` |
| Project ID | `my-project` |
| Repository | `ace-repository` |
| Image | `hello-app` |
| Tag | `v1` |

Artifact Registry requires the repository to exist before you push an image. The complete image path must include the location hostname, project ID, repository, image name, and optional tag. citeturn986975search20

---

## 7. Repository modes

### Standard repository

Stores private artifacts directly in Artifact Registry.

Use it when:

- Your organization builds its own images.
- You need controlled image storage.
- You want repository-level IAM.
- You need retention, cleanup, scanning, and audit controls.

### Remote repository

Caches artifacts obtained from an external source such as Docker Hub.

Benefits:

- Reduces dependency on an external registry.
- Can reduce repeated downloads.
- Helps protect against upstream availability and rate-limit issues.

### Virtual repository

Provides one logical endpoint over multiple upstream repositories.

Use it when developers should pull from one common endpoint while artifacts may physically exist in multiple repositories.

### ACE focus

For most ACE scenarios involving application images, choose a **standard Docker repository**.

---

## 8. Artifact Registry IAM roles

Important predefined roles:

| Role | Purpose |
|---|---|
| `roles/artifactregistry.reader` | View metadata and download artifacts |
| `roles/artifactregistry.writer` | Read and upload artifacts |
| `roles/artifactregistry.repoAdmin` | Manage artifacts and repository settings |
| `roles/artifactregistry.admin` | Full Artifact Registry administration |

Google Cloud allows Artifact Registry roles to be granted at either the project or individual repository level. For least privilege, repository-level access is preferable when a principal only requires one repository. citeturn600990search3turn600990search9

### Typical access model

| Principal | Recommended role |
|---|---|
| Developer pushing images | Artifact Registry Writer |
| CI/CD service account | Artifact Registry Writer |
| GKE node service account | Artifact Registry Reader |
| Repository administrator | Repository Administrator |
| Auditor | Artifact Registry Reader |

---

# Mini Lab 12: Build and push a Docker image

## Lab architecture

```text
Local machine / Cloud Shell
        |
        | docker push
        v
Artifact Registry
asia-south1-docker.pkg.dev
        |
        | docker pull
        v
Local machine or GKE
```

## Estimated resources

- One Artifact Registry repository
- One small test image
- No running GKE cluster required in this phase

---

## Part A: Prepare the application

Create a directory:

```bash
mkdir artifact-gke-lab
cd artifact-gke-lab
```

Create `app.py`:

```python
from flask import Flask

app = Flask(__name__)


@app.route("/")
def home():
    return {
        "message": "Hello from Google Artifact Registry!",
        "version": "v1"
    }


@app.route("/health")
def health():
    return {"status": "healthy"}, 200


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
```

Create `requirements.txt`:

```text
Flask==3.1.1
gunicorn==23.0.0
```

Create `Dockerfile`:

```dockerfile
FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

RUN useradd --create-home appuser
USER appuser

EXPOSE 8080

CMD ["gunicorn", "--bind", "0.0.0.0:8080", "app:app"]
```

Create `.dockerignore`:

```text
.git
.gitignore
__pycache__
*.pyc
.env
README.md
```

---

## Part B: Test locally

```bash
docker build -t hello-app:v1 .
```

Verify:

```bash
docker images
```

Run:

```bash
docker run -d \
  --name hello-container \
  -p 8080:8080 \
  hello-app:v1
```

Test:

```bash
curl http://localhost:8080
curl http://localhost:8080/health
```

View logs:

```bash
docker logs hello-container
```

Clean up the local container:

```bash
docker stop hello-container
docker rm hello-container
```

---

## Part C: Enable Artifact Registry

Set variables:

```bash
export PROJECT_ID="$(gcloud config get-value project)"
export REGION="asia-south1"
export REPOSITORY="ace-docker-repo"
export IMAGE="hello-app"
export TAG="v1"
```

Confirm:

```bash
echo "$PROJECT_ID"
```

Enable the API:

```bash
gcloud services enable artifactregistry.googleapis.com
```

---

## Part D: Create the repository through the GUI

1. Open **Google Cloud Console**.
2. Select the required project.
3. Navigate to **Artifact Registry → Repositories**.
4. Click **Create repository**.
5. Enter:
   - Name: `ace-docker-repo`
   - Format: `Docker`
   - Mode: `Standard`
   - Location type: `Region`
   - Region: `asia-south1`
6. Keep the default Google-managed encryption unless CMEK is required.
7. Click **Create**.

### Verify through the GUI

Open the repository and check:

- Format
- Location
- Encryption type
- Repository path
- IAM permissions
- Cleanup policies

---

## Part E: Create the repository using CLI

Do not repeat this step when it was already created through the GUI.

```bash
gcloud artifacts repositories create "$REPOSITORY" \
  --repository-format=docker \
  --location="$REGION" \
  --description="ACE Docker image repository"
```

Verify:

```bash
gcloud artifacts repositories list \
  --location="$REGION"
```

Describe it:

```bash
gcloud artifacts repositories describe "$REPOSITORY" \
  --location="$REGION"
```

---

## Part F: Configure Docker authentication

```bash
gcloud auth configure-docker "${REGION}-docker.pkg.dev"
```

This updates Docker’s configuration so Docker can authenticate to the specified Artifact Registry hostname through the Google Cloud CLI. citeturn986975search9turn986975search43

Verify:

```bash
cat ~/.docker/config.json
```

On Windows PowerShell, the file is normally under:

```powershell
Get-Content "$HOME\.docker\config.json"
```

---

## Part G: Tag the image

```bash
export IMAGE_URI="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPOSITORY}/${IMAGE}:${TAG}"

docker tag hello-app:v1 "$IMAGE_URI"
```

Verify:

```bash
docker images
```

Expected format:

```text
asia-south1-docker.pkg.dev/PROJECT_ID/ace-docker-repo/hello-app   v1
```

---

## Part H: Push the image

```bash
docker push "$IMAGE_URI"
```

Artifact Registry stores each unique layer only as needed, so unchanged image layers can be reused between versions.

Official push and pull documentation: citeturn986975search0

---

## Part I: Verify the image

### CLI

```bash
gcloud artifacts docker images list \
  "${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPOSITORY}"
```

Include tags:

```bash
gcloud artifacts docker images list \
  "${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPOSITORY}" \
  --include-tags
```

### GUI

1. Go to **Artifact Registry → Repositories**.
2. Open `ace-docker-repo`.
3. Open `hello-app`.
4. Verify:
   - `v1` tag
   - Image digest
   - Upload time
   - Image size

---

## Part J: Test pulling the image

Remove the tagged local image:

```bash
docker rmi "$IMAGE_URI"
```

Pull it again:

```bash
docker pull "$IMAGE_URI"
```

Run:

```bash
docker run --rm -p 8080:8080 "$IMAGE_URI"
```

Test:

```bash
curl http://localhost:8080
```

---

## Common Artifact Registry errors

### `denied: Permission denied`

Cause:

- Missing `roles/artifactregistry.writer`
- Missing `roles/cloudbuild.builds.editor`
- Wrong authenticated account
- Repository belongs to another project

Check:

```bash
gcloud auth list
gcloud config get-value project
```

Grant writer access:

```bash
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="user:USER_EMAIL" \
  --role="roles/artifactregistry.writer"
```

Use repository-level IAM for stronger least privilege:

```bash
gcloud artifacts repositories add-iam-policy-binding "$REPOSITORY" \
  --location="$REGION" \
  --member="user:USER_EMAIL" \
  --role="roles/artifactregistry.writer"
```

### `name unknown: Repository not found`

Check:

```bash
gcloud artifacts repositories list
```

Possible causes:

- Repository was not created.
- Wrong region.
- Wrong project ID.
- Repository name is incorrect.

### `unauthorized: authentication failed`

Run:

```bash
gcloud auth login
gcloud auth configure-docker "${REGION}-docker.pkg.dev"
```

### Incorrect image path

Correct format:

```text
LOCATION-docker.pkg.dev/PROJECT_ID/REPOSITORY/IMAGE:TAG
```

Incorrect:

```text
PROJECT_ID/REPOSITORY/IMAGE
```

---

# Phase 13: GKE Basics

# 1. Kubernetes overview

Kubernetes is an orchestration platform used to deploy, scale, manage, and recover containerized applications.

It solves problems such as:

- Placing containers on machines
- Restarting failed containers
- Scaling application replicas
- Service discovery
- Load balancing
- Rolling updates
- Configuration management
- Secret management
- Persistent storage

---

# 2. What is GKE?

Google Kubernetes Engine is Google Cloud’s managed Kubernetes service.

Google manages the Kubernetes control plane, including:

- Kubernetes API server
- Scheduler
- Controller manager
- Control-plane availability
- Control-plane upgrades and patching
- Integration with Google Cloud IAM, networking, logging, and monitoring

Depending on cluster mode, customers manage some or all of:

- Node pools
- Node machine types
- Workload manifests
- Pod resource requests and limits
- Application configuration
- Kubernetes RBAC
- Network policies
- Scaling settings

---

## 3. GKE architecture

```text
                    GKE Control Plane
             ┌──────────────────────────┐
kubectl ---->| Kubernetes API Server    |
             | Scheduler                |
             | Controller Managers      |
             └─────────────┬────────────┘
                           |
       ┌───────────────────┴───────────────────┐
       │                                       │
 Node pool A                              Node pool B
┌─────────────────┐                    ┌─────────────────┐
│ Node 1          │                    │ Node 3          │
│ kubelet         │                    │ kubelet         │
│ containerd      │                    │ containerd      │
│ Pods            │                    │ Pods            │
├─────────────────┤                    └─────────────────┘
│ Node 2          │
│ Pods            │
└─────────────────┘
```

---

# 4. Install `kubectl`

`kubectl` is the main command-line tool for communicating with the Kubernetes API server.

Google Cloud also requires `gke-gcloud-auth-plugin` for GKE authentication. citeturn986975search7turn986975search17

## Cloud Shell

Cloud Shell generally includes:

- `gcloud`
- `kubectl`
- GKE authentication support

Check:

```bash
gcloud version
kubectl version --client
gke-gcloud-auth-plugin --version
```

## Using gcloud components

```bash
gcloud components install kubectl
gcloud components install gke-gcloud-auth-plugin
```

Available gcloud components can be examined using:

```bash
gcloud components list
```

The component manager installs the versions compatible with the installed Google Cloud CLI. citeturn986975search34

## Ubuntu/Debian package

```bash
sudo apt-get update
sudo apt-get install -y kubectl google-cloud-cli-gke-gcloud-auth-plugin
```

## Verify

```bash
kubectl version --client
gke-gcloud-auth-plugin --version
```

---

# 5. GKE Standard versus Autopilot

## GKE Standard

In Standard mode, you manage node infrastructure choices.

You select:

- Machine type
- Number of nodes
- Node pools
- Boot disk type and size
- Node service account
- Autoscaling boundaries
- Upgrade configuration
- Node locations
- Taints and labels

### Use Standard when

- You require direct node-level control.
- You need custom machine types or specialized hardware.
- You need privileged workloads supported by your security policy.
- You need precise control over node pools.
- You have system workloads with special infrastructure requirements.
- You need GPUs, TPUs, local SSDs, or specific scheduling configurations.

## GKE Autopilot

In Autopilot mode, Google manages infrastructure configuration, including nodes, scaling, baseline security, and many operational settings. Compute capacity is provisioned based on the Kubernetes workload manifests. citeturn986975search23

### Use Autopilot when

- You want minimal cluster administration.
- Your team primarily manages applications, not nodes.
- You want automatic node provisioning.
- You want stronger secure-by-default settings.
- Workloads fit within Autopilot restrictions and supported configurations.

## Comparison

| Area | Standard | Autopilot |
|---|---|---|
| Node management | Customer | Google |
| Node pools | Customer creates and manages | Automatically managed |
| Machine selection | Direct control | Derived from workload requirements |
| Node autoscaling | Configured by customer | Automatically managed |
| Pod requests | Strongly recommended | Required/defaulted and used for billing/provisioning |
| Operational effort | Higher | Lower |
| Customization | Highest | More restricted |
| Best fit | Specialized infrastructure | General application workloads |

Autopilot automatically determines node quantity and size from Pods, while Standard begins with manually selected node infrastructure unless autoscaling and automatic provisioning features are configured. citeturn986975search37

### ACE exam shortcut

- **Maximum control** → Standard
- **Minimum infrastructure management** → Autopilot
- **Need to manually add/remove node pools** → Standard
- **Google should handle node provisioning and scaling** → Autopilot

---

# 6. Zonal versus regional cluster

## Zonal cluster

A zonal cluster has a control plane associated with one zone.

Example:

```text
asia-south1-a
```

Use it mainly for:

- Development
- Testing
- Non-critical applications
- Lower-cost labs

## Regional cluster

A regional cluster replicates the control plane across multiple zones in a region.

Example:

```text
asia-south1
├── asia-south1-a
├── asia-south1-b
└── asia-south1-c
```

Benefits:

- Higher control-plane availability
- Workload distribution across zones
- Better production resilience
- Maintenance can be distributed

Google recommends regional clusters for production because they generally provide higher availability. The cluster’s region cannot be changed after creation. citeturn986975search13

### Important cost point

In Standard mode, a regional cluster can create nodes in multiple zones.

For example:

```text
--num-nodes=2
```

may mean **two nodes per zone**, not necessarily two nodes across the entire region, depending on the node locations and command configuration.

Always inspect:

```bash
gcloud container clusters describe CLUSTER_NAME \
  --region=REGION
```

---

# 7. Private GKE cluster

A private cluster is a VPC-native GKE cluster that can use private IP addresses for worker nodes.

Private nodes:

- Do not require external IP addresses.
- Communicate internally over the VPC.
- Usually require Cloud NAT for general outbound internet access.
- Can access supported Google APIs using Private Google Access or other private connectivity patterns.

Google’s current GKE networking model provides controls for node and control-plane endpoint isolation. citeturn600990search34

## Main private-cluster concepts

### Private nodes

Nodes have internal IP addresses and do not receive external IP addresses.

### Control-plane endpoint

Depending on configuration, the Kubernetes API can be accessed through:

- DNS-based endpoint
- External IP endpoint
- Internal IP endpoint

### Authorized networks

Restricts which source CIDR ranges can reach an exposed control-plane IP endpoint.

### Master/control-plane IPv4 range

Certain private-cluster configurations use a dedicated CIDR block for communication with the control plane.

Example:

```text
172.16.0.0/28
```

### Cloud NAT

Private nodes need Cloud NAT when they must reach public internet destinations without external IP addresses.

### ACE scenario

A company requires GKE worker nodes without public IP addresses but still needs outbound software downloads.

Recommended design:

```text
Private GKE nodes
      ↓
Cloud NAT
      ↓
Internet
```

---

# 8. Node pools

A node pool is a group of GKE nodes with the same general configuration.

A cluster can contain multiple node pools.

Example:

```text
Cluster
├── general-pool
│   ├── e2-standard-2
│   └── e2-standard-2
├── memory-pool
│   ├── n2-highmem-4
│   └── n2-highmem-4
└── gpu-pool
    └── GPU node
```

Node pools allow workloads to be separated by:

- Machine type
- CPU or memory
- GPU availability
- Spot VM usage
- Node labels
- Taints
- Service account
- Disk size and type
- Autoscaling configuration

### Example use case

```text
Frontend Pods → general-pool
Data processing Pods → high-memory-pool
ML Pods → gpu-pool
```

### Scheduling to a node pool

Give nodes a label:

```bash
gcloud container node-pools create high-memory-pool \
  --cluster=ace-standard-cluster \
  --region=asia-south1 \
  --machine-type=n2-highmem-4 \
  --node-labels=workload=memory
```

Pod configuration:

```yaml
spec:
  nodeSelector:
    workload: memory
```

---

# 9. Important Kubernetes objects

## Pod

A Pod is the smallest deployable unit in Kubernetes.

A Pod can contain:

- One main application container
- One or more supporting sidecar containers
- Shared storage volumes
- Shared network namespace

Containers in the same Pod share:

- Pod IP
- Port space
- Volumes
- Lifecycle

### Important point

Pods are temporary and replaceable. Do not depend on a specific Pod IP or name.

---

## Deployment

A Deployment manages stateless application Pods.

It supports:

- Desired replica count
- Rolling updates
- Rollbacks
- Self-healing through ReplicaSets
- Declarative application updates

Example:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: hello-app
  template:
    metadata:
      labels:
        app: hello-app
    spec:
      containers:
      - name: hello-app
        image: IMAGE_URI
        ports:
        - containerPort: 8080
```

---

## Service

A Service provides a stable network endpoint for a group of Pods.

Pods are selected through labels.

### Service types

| Type | Accessibility | Use case |
|---|---|---|
| `ClusterIP` | Inside cluster | Internal microservice |
| `NodePort` | Node IP and allocated port | Testing or underlying mechanism |
| `LoadBalancer` | External or internal load balancer | Expose application |
| `ExternalName` | DNS alias | Reference an external service |

Creating a `LoadBalancer` Service in GKE triggers Google Cloud integration to provision a load-balancing resource for the application. citeturn600990search2turn600990search30

---

# Mini Lab 13: Create GKE cluster, deploy and expose an app

## Architecture

```text
Internet user
      |
External IP
      |
Kubernetes Service: LoadBalancer
      |
Deployment
      |
hello-app Pods
      |
Artifact Registry image
```

---

## Part A: Set variables

```bash
export PROJECT_ID="$(gcloud config get-value project)"
export REGION="asia-south1"
export ZONE="asia-south1-a"
export CLUSTER_NAME="ace-standard-cluster"
export REPOSITORY="ace-docker-repo"
export IMAGE="hello-app"
export TAG="v1"

export IMAGE_URI="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPOSITORY}/${IMAGE}:${TAG}"
```

Set defaults:

```bash
gcloud config set compute/region "$REGION"
gcloud config set compute/zone "$ZONE"
```

Enable APIs:

```bash
gcloud services enable \
  container.googleapis.com \
  artifactregistry.googleapis.com \
  compute.googleapis.com \
  monitoring.googleapis.com \
  logging.googleapis.com
```

---

## Part B: Create a Standard cluster through the GUI

1. Go to **Kubernetes Engine → Clusters**.
2. Click **Create**.
3. Select **Standard**.
4. Configure:
   - Name: `ace-standard-cluster`
   - Location type: `Zonal` for a low-cost lab
   - Zone: `asia-south1-a`
5. Under the default node pool:
   - Nodes: `2`
   - Machine type: a small general-purpose machine appropriate for the lab
   - Boot disk: balanced persistent disk
6. Under security:
   - Select an appropriate node service account.
   - Avoid broad permissions.
7. Under observability:
   - Keep Cloud Logging and Cloud Monitoring enabled for the lab.
8. Click **Create**.

### Regional production configuration

For a production-style cluster:

- Location type: Regional
- Region: `asia-south1`
- Nodes distributed across multiple zones
- Release channel enabled
- Autoscaling configured
- Private nodes considered
- Workload Identity Federation enabled

---

## Part C: Create a Standard cluster using CLI

For a cost-controlled zonal lab:

```bash
gcloud container clusters create "$CLUSTER_NAME" \
  --zone="$ZONE" \
  --machine-type=e2-standard-2 \
  --num-nodes=2 \
  --disk-type=pd-balanced \
  --disk-size=50GB \
  --release-channel=regular \
  --enable-ip-alias \
  --workload-pool="${PROJECT_ID}.svc.id.goog" \
  --enable-autorepair \
  --enable-autoupgrade
```

For a regional cluster:

```bash
gcloud container clusters create ace-regional-cluster \
  --region="$REGION" \
  --node-locations="${REGION}-a,${REGION}-b,${REGION}-c" \
  --machine-type=e2-standard-2 \
  --num-nodes=1 \
  --release-channel=regular \
  --enable-ip-alias \
  --workload-pool="${PROJECT_ID}.svc.id.goog" \
  --enable-autorepair \
  --enable-autoupgrade
```

Remember that node count for a regional pool can apply per selected zone.

---

## Part D: Create an Autopilot cluster

### GUI

1. Go to **Kubernetes Engine → Clusters**.
2. Click **Create**.
3. Select **Autopilot**.
4. Enter:
   - Name: `ace-autopilot-cluster`
   - Region: `asia-south1`
5. Configure networking and security if required.
6. Click **Create**.

### CLI

```bash
gcloud container clusters create-auto ace-autopilot-cluster \
  --region="$REGION" \
  --release-channel=regular
```

---

## Part E: Connect `kubectl` to the cluster

For the zonal Standard cluster:

```bash
gcloud container clusters get-credentials "$CLUSTER_NAME" \
  --zone="$ZONE" \
  --project="$PROJECT_ID"
```

For a regional cluster:

```bash
gcloud container clusters get-credentials ace-regional-cluster \
  --region="$REGION" \
  --project="$PROJECT_ID"
```

This updates the local kubeconfig.

Check contexts:

```bash
kubectl config get-contexts
kubectl config current-context
```

Test access:

```bash
kubectl cluster-info
kubectl get namespaces
```

---

## Part F: View cluster inventory

### GCP CLI

```bash
gcloud container clusters list
```

Describe the cluster:

```bash
gcloud container clusters describe "$CLUSTER_NAME" \
  --zone="$ZONE"
```

### Kubernetes CLI

```bash
kubectl get nodes
kubectl get nodes -o wide
kubectl get pods --all-namespaces
kubectl get services --all-namespaces
kubectl get deployments --all-namespaces
```

Detailed node information:

```bash
kubectl describe node NODE_NAME
```

Resource usage:

```bash
kubectl top nodes
kubectl top pods --all-namespaces
```

`kubectl top` depends on metrics being available.

### GUI inventory

Navigate to:

- **GKE → Clusters** for cluster inventory
- **GKE → Nodes** or cluster node details
- **GKE → Workloads** for Deployments, StatefulSets and Pods
- **GKE → Services & Ingress** for Services and traffic endpoints
- **Logging → Logs Explorer** for container logs
- **Monitoring → Dashboards → GKE** for metrics

---

## Part G: Configure GKE access to Artifact Registry

GKE must be able to pull the application image.

For same-project repositories, grant the node service account:

```text
roles/artifactregistry.reader
```

Google documents that GKE can pull images from same-project Artifact Registry repositories when the relevant node service account has Artifact Registry Reader access and the node configuration has appropriate scopes. citeturn600990search18turn600990search9

### Identify node service account

```bash
gcloud container clusters describe "$CLUSTER_NAME" \
  --zone="$ZONE" \
  --format="value(nodeConfig.serviceAccount)"
```

When the output is `default`, the nodes normally use:

```text
PROJECT_NUMBER-compute@developer.gserviceaccount.com
```

Obtain project number:

```bash
export PROJECT_NUMBER="$(gcloud projects describe "$PROJECT_ID" \
  --format='value(projectNumber)')"

export NODE_SA="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com"
```

Grant access at the repository level:

```bash
gcloud artifacts repositories add-iam-policy-binding "$REPOSITORY" \
  --location="$REGION" \
  --member="serviceAccount:${NODE_SA}" \
  --role="roles/artifactregistry.reader"
```

For a custom node service account:

```bash
export NODE_SA_NAME="gke-node-sa"

gcloud iam service-accounts create "$NODE_SA_NAME" \
  --display-name="GKE node service account"

export NODE_SA="${NODE_SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${NODE_SA}" \
  --role="roles/logging.logWriter"

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${NODE_SA}" \
  --role="roles/monitoring.metricWriter"

gcloud artifacts repositories add-iam-policy-binding "$REPOSITORY" \
  --location="$REGION" \
  --member="serviceAccount:${NODE_SA}" \
  --role="roles/artifactregistry.reader"
```

---

## Part H: Deploy using CLI

Create `deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello-app
  labels:
    app: hello-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: hello-app
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 0
      maxSurge: 1
  template:
    metadata:
      labels:
        app: hello-app
    spec:
      containers:
      - name: hello-app
        image: IMAGE_URI
        imagePullPolicy: IfNotPresent
        ports:
        - name: http
          containerPort: 8080
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
          limits:
            cpu: "500m"
            memory: "256Mi"
        readinessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 3
          periodSeconds: 5
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 10
```

Replace the placeholder:

```bash
sed "s|IMAGE_URI|${IMAGE_URI}|g" deployment.yaml > deployment-rendered.yaml
```

Apply:

```bash
kubectl apply -f deployment-rendered.yaml
```

Observe rollout:

```bash
kubectl rollout status deployment/hello-app
```

Inspect:

```bash
kubectl get deployments
kubectl get replicasets
kubectl get pods
kubectl get pods -o wide
```

View logs:

```bash
kubectl logs -l app=hello-app --tail=100
```

---

## Part I: Deploy using the GUI

1. Navigate to **Kubernetes Engine → Workloads**.
2. Click **Deploy**.
3. Select the existing cluster.
4. Choose **Existing container image**.
5. Browse Artifact Registry and select:
   - Repository: `ace-docker-repo`
   - Image: `hello-app`
   - Tag: `v1`
6. Set:
   - Application name: `hello-app`
   - Namespace: `default`
   - Replicas: `2`
7. Configure container port `8080`.
8. Configure resource requests and limits.
9. Click **Deploy**.

The GKE Workloads console supports deploying a basic Deployment from an image stored in Artifact Registry. citeturn600990search24

---

## Part J: Expose the application

Create `service.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: hello-app-service
spec:
  type: LoadBalancer
  selector:
    app: hello-app
  ports:
  - name: http
    protocol: TCP
    port: 80
    targetPort: 8080
```

Apply:

```bash
kubectl apply -f service.yaml
```

Check:

```bash
kubectl get services
kubectl get service hello-app-service --watch
```

Wait until `EXTERNAL-IP` is populated.

Get the IP:

```bash
export EXTERNAL_IP="$(kubectl get service hello-app-service \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}')"

echo "$EXTERNAL_IP"
```

Test:

```bash
curl "http://${EXTERNAL_IP}"
curl "http://${EXTERNAL_IP}/health"
```

### Expose through GUI

1. Go to **GKE → Workloads**.
2. Open `hello-app`.
3. Click **Actions → Expose**.
4. Configure:
   - Port: `80`
   - Target port: `8080`
   - Protocol: TCP
   - Service type: Load balancer
5. Click **Expose**.
6. Open **Services & Ingress**.
7. Wait for the external IP.

Google’s GKE console exposes applications by creating Kubernetes Service resources and mapping a service port to the application’s target port. citeturn600990search2

---

## Part K: Update the application

Change:

```python
"version": "v1"
```

to:

```python
"version": "v2"
```

Build and push:

```bash
export TAG="v2"
export IMAGE_URI_V2="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPOSITORY}/${IMAGE}:${TAG}"

docker build -t "$IMAGE_URI_V2" .
docker push "$IMAGE_URI_V2"
```

Update the Deployment:

```bash
kubectl set image deployment/hello-app \
  hello-app="$IMAGE_URI_V2"
```

Watch rollout:

```bash
kubectl rollout status deployment/hello-app
kubectl get pods --watch
```

View history:

```bash
kubectl rollout history deployment/hello-app
```

Rollback:

```bash
kubectl rollout undo deployment/hello-app
```

---

## Common GKE deployment errors

### `ImagePullBackOff`

Check:

```bash
kubectl describe pod POD_NAME
```

Likely causes:

- Incorrect image URL
- Image tag does not exist
- Node service account lacks Artifact Registry Reader
- Cross-project repository permissions are missing
- Repository region or project is incorrect

### `CrashLoopBackOff`

Check:

```bash
kubectl logs POD_NAME
kubectl logs POD_NAME --previous
kubectl describe pod POD_NAME
```

Likely causes:

- Application fails during startup
- Incorrect command
- Missing environment variable
- Invalid port
- Failed dependency connection
- Liveness probe is too aggressive

### Pod remains `Pending`

Check:

```bash
kubectl describe pod POD_NAME
kubectl get events --sort-by=.metadata.creationTimestamp
```

Likely causes:

- Insufficient CPU or memory
- Node selector does not match any node
- Untolerated taint
- Unbound PersistentVolumeClaim
- Node pool has reached its maximum size
- Resource request is unsupported in Autopilot

### External IP remains pending

Check:

```bash
kubectl describe service hello-app-service
kubectl get events
```

Possible causes:

- Quota restrictions
- Load-balancer provisioning delay
- Organization policies
- Network or subnet configuration
- Missing permissions

---

# Phase 14: GKE Operations

# 1. Add a node pool

Node pools apply to Standard clusters. Autopilot manages nodes for you.

## GUI

1. Navigate to **GKE → Clusters**.
2. Open the Standard cluster.
3. Select **Nodes → Add node pool**.
4. Enter:
   - Name: `high-memory-pool`
   - Machine type: appropriate high-memory machine
   - Initial nodes: `1`
5. Optionally configure:
   - Autoscaling
   - Node labels
   - Taints
   - Boot disk
   - Service account
   - Upgrade strategy
6. Click **Create**.

## CLI

```bash
gcloud container node-pools create high-memory-pool \
  --cluster="$CLUSTER_NAME" \
  --zone="$ZONE" \
  --machine-type=e2-highmem-2 \
  --num-nodes=1 \
  --disk-type=pd-balanced \
  --disk-size=50GB \
  --node-labels=workload=memory \
  --enable-autorepair \
  --enable-autoupgrade
```

Verify:

```bash
gcloud container node-pools list \
  --cluster="$CLUSTER_NAME" \
  --zone="$ZONE"
```

```bash
kubectl get nodes --show-labels
```

---

# 2. Edit a node pool

Some settings can be updated in place, while others require creating a replacement node pool and migrating workloads.

## Enable autoscaling

```bash
gcloud container clusters update "$CLUSTER_NAME" \
  --zone="$ZONE" \
  --enable-autoscaling \
  --node-pool=high-memory-pool \
  --min-nodes=1 \
  --max-nodes=4
```

## Change node count manually

```bash
gcloud container clusters resize "$CLUSTER_NAME" \
  --zone="$ZONE" \
  --node-pool=high-memory-pool \
  --num-nodes=2
```

## Update node labels

```bash
gcloud container node-pools update high-memory-pool \
  --cluster="$CLUSTER_NAME" \
  --zone="$ZONE" \
  --node-labels=workload=memory,environment=dev
```

### Replacement strategy

When a machine type or another immutable characteristic must change:

1. Create a new node pool.
2. Verify nodes join the cluster.
3. Cordon old nodes.
4. Drain workloads.
5. Delete the old node pool.

```bash
kubectl cordon OLD_NODE_NAME

kubectl drain OLD_NODE_NAME \
  --ignore-daemonsets \
  --delete-emptydir-data
```

---

# 3. Remove a node pool

## GUI

1. Open the cluster.
2. Go to **Nodes**.
3. Select the node pool.
4. Click **Delete**.
5. Confirm deletion.

## CLI

```bash
gcloud container node-pools delete high-memory-pool \
  --cluster="$CLUSTER_NAME" \
  --zone="$ZONE"
```

### Before deletion

Check workloads:

```bash
kubectl get pods -A -o wide
```

Ensure:

- Other node pools have capacity.
- PodDisruptionBudgets permit eviction.
- Stateful workloads are safe.
- Workloads do not require unique node labels or taints from the pool.
- Persistent disks can reattach where required.

---

# 4. Node-pool autoscaling

The GKE cluster autoscaler changes the number of nodes according to Pod scheduling demand.

It reacts mainly when:

- Pods cannot be scheduled because of insufficient resources.
- Existing nodes are underutilized and workloads can be moved safely.

It does not directly scale because CPU utilization crossed a percentage unless that utilization first causes workload scaling, such as HPA creating more Pods.

For Standard clusters, cluster autoscaling is configured on node pools. Autopilot automatically provisions and removes node infrastructure according to workload requirements. citeturn986975search12

## Enable autoscaling during creation

```bash
gcloud container node-pools create autoscaling-pool \
  --cluster="$CLUSTER_NAME" \
  --zone="$ZONE" \
  --machine-type=e2-standard-2 \
  --enable-autoscaling \
  --min-nodes=1 \
  --max-nodes=5 \
  --num-nodes=1
```

## Disable autoscaling

```bash
gcloud container clusters update "$CLUSTER_NAME" \
  --zone="$ZONE" \
  --node-pool=autoscaling-pool \
  --no-enable-autoscaling
```

## Three different scaling layers

```text
HPA
Scales number of Pods
        ↓
Cluster Autoscaler
Scales number of nodes
        ↓
Compute infrastructure
Provides CPU and memory
```

VPA is different:

```text
VPA
Changes Pod CPU/memory requests
```

---

# 5. Pods

Important operational commands:

```bash
kubectl get pods
kubectl get pods -A
kubectl get pods -o wide
kubectl describe pod POD_NAME
kubectl logs POD_NAME
kubectl logs POD_NAME --previous
kubectl exec -it POD_NAME -- sh
kubectl delete pod POD_NAME
```

When a Pod managed by a Deployment is deleted, the Deployment’s ReplicaSet creates a replacement.

### Pod lifecycle states

| State | Meaning |
|---|---|
| Pending | Accepted but not fully scheduled or started |
| Running | Bound to a node and containers started |
| Succeeded | All containers completed successfully |
| Failed | At least one container terminated unsuccessfully |
| Unknown | Pod state could not be determined |

### Container-level waiting reasons

- `ContainerCreating`
- `ErrImagePull`
- `ImagePullBackOff`
- `CrashLoopBackOff`
- `CreateContainerConfigError`

---

# 6. Services

## ClusterIP

```yaml
spec:
  type: ClusterIP
```

Use for internal communication:

```text
frontend → backend-service → backend Pods
```

## LoadBalancer

```yaml
spec:
  type: LoadBalancer
```

Use when the service needs an externally or internally provisioned load balancer.

## Internal load balancer

A GKE Service can be configured for internal load balancing using the relevant GKE annotations and network configuration.

Use when:

- Only VPC clients should reach the application.
- The service is an internal API.
- Public exposure is prohibited.

## Useful commands

```bash
kubectl get services
kubectl get endpoints
kubectl describe service SERVICE_NAME
```

If the Service has no endpoints:

```bash
kubectl get pods --show-labels
kubectl get service SERVICE_NAME -o yaml
kubectl get endpoints SERVICE_NAME
```

The most common reason is that the Service selector does not match the Pod labels.

---

# 7. StatefulSets

A StatefulSet manages stateful applications whose Pods need stable identities and often persistent storage.

Unlike Deployment Pods, StatefulSet Pods are not treated as fully interchangeable. StatefulSets provide stable identities and ordered management for their Pods. citeturn986975search46turn986975search47

Example Pod names:

```text
mysql-0
mysql-1
mysql-2
```

These names remain predictable.

## StatefulSet features

- Stable Pod names
- Stable network identity
- Ordered deployment
- Ordered scaling
- Ordered termination
- Per-Pod persistent storage through volume claim templates

## Common use cases

- Databases
- Kafka brokers
- ZooKeeper
- Elasticsearch
- Distributed systems requiring stable member identities

## Deployment versus StatefulSet

| Deployment | StatefulSet |
|---|---|
| Stateless workloads | Stateful workloads |
| Pods interchangeable | Pods have stable identities |
| Random Pod suffixes | Ordered names such as `app-0` |
| Shared or ephemeral storage | Usually individual persistent volumes |
| Parallel behavior common | Ordered operations supported |

### Important design guidance

Although Kubernetes can run databases, ACE scenarios may prefer a managed database such as Cloud SQL, Spanner, or AlloyDB when the organization wants reduced database administration.

---

# 8. Horizontal Pod Autoscaler

HPA changes the number of Pod replicas according to observed metrics.

Typical metrics:

- CPU utilization
- Memory utilization
- Custom metrics
- External metrics

HPA can control scalable workloads such as Deployments and StatefulSets through their scale interface. citeturn986975search8

## HPA flow

```text
Traffic increases
      ↓
Pod CPU rises
      ↓
HPA observes metric
      ↓
Deployment replica count increases
      ↓
More Pods are created
```

## Critical requirement

HPA based on CPU utilization needs CPU requests.

Example:

```yaml
resources:
  requests:
    cpu: "100m"
```

Without CPU requests, percentage CPU utilization cannot be calculated properly for the target.

## CLI method

```bash
kubectl autoscale deployment hello-app \
  --cpu-percent=60 \
  --min=2 \
  --max=10
```

Inspect:

```bash
kubectl get hpa
kubectl describe hpa hello-app
```

## YAML method

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: hello-app-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: hello-app
  minReplicas: 2
  maxReplicas: 10
  behavior:
    scaleUp:
      stabilizationWindowSeconds: 0
      policies:
      - type: Percent
        value: 100
        periodSeconds: 60
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 50
        periodSeconds: 60
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 60
```

Apply:

```bash
kubectl apply -f hpa.yaml
```

---

# 9. Vertical Pod Autoscaler

VPA adjusts the CPU and memory requests of Pods based on observed usage.

## VPA flow

```text
Pod resource usage observed
        ↓
VPA produces recommendations
        ↓
CPU/memory requests are adjusted
        ↓
Pods may be recreated depending on mode
```

VPA is primarily useful for rightsizing relatively steady workloads. Google recommends HPA for fast demand spikes; VPA is not intended as the primary response to short-lived traffic bursts. VPA is enabled by default in Autopilot clusters. citeturn986975search31

## VPA modes

| Mode | Behavior |
|---|---|
| `Off` | Generates recommendations only |
| `Initial` | Applies recommendations when Pods are initially created |
| `Recreate` or automatic behavior | May evict/recreate Pods to apply recommendations, depending on supported configuration |

Example:

```yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: hello-app-vpa
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: hello-app
  updatePolicy:
    updateMode: "Off"
```

Check recommendations:

```bash
kubectl describe vpa hello-app-vpa
```

### HPA and VPA together

Avoid having HPA and VPA independently modify the same CPU or memory dimension without understanding the interaction.

A safer pattern can be:

- HPA scales replicas using CPU.
- VPA recommendation mode suggests memory requests.

---

# 10. Autopilot Pod resource requests

Autopilot provisions infrastructure according to Pod resource requests.

Example:

```yaml
resources:
  requests:
    cpu: "250m"
    memory: "512Mi"
  limits:
    cpu: "500m"
    memory: "1Gi"
```

Autopilot may:

- Apply defaults when supported requests are omitted.
- Adjust requests to meet platform minimums or CPU-to-memory constraints.
- Schedule the Pod onto automatically provisioned infrastructure.
- Use the adjusted workload resources for provisioning and billing behavior.

### ACE point

For Autopilot, focus on specifying appropriate **Pod-level resources**, not choosing node machine types.

---

# 11. Traffic splitting in GKE

Traffic splitting sends percentages of traffic to different application versions.

Example:

```text
90% → application v1
10% → application v2
```

Use cases:

- Canary release
- Blue-green migration
- Controlled rollout
- A/B testing
- Risk reduction

## GKE Gateway approach

GKE Gateway supports weighted backend references through HTTPRoute rules.

Conceptual example:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: hello-route
spec:
  parentRefs:
  - name: external-gateway
  rules:
  - backendRefs:
    - name: hello-v1
      port: 80
      weight: 90
    - name: hello-v2
      port: 80
      weight: 10
```

GKE traffic management can route 90% of matching requests to one Service and 10% to another. citeturn600990search10

### ACE depth

For ACE, understand:

- Why traffic splitting is used
- Services represent separate versions
- Gateway or service-mesh routing can assign percentages
- Canary deployment reduces release risk

Detailed multi-cluster traffic splitting is more advanced than the usual ACE depth, but the operational concept is still useful. Google’s documented example uses weighted HTTPRoute backends to send a controlled proportion of traffic to canary services or clusters. citeturn600990search0

---

# 12. Workload Identity Federation for GKE

Workload Identity Federation for GKE lets Kubernetes workloads access Google Cloud APIs without storing long-lived service-account keys in Pods.

It is Google’s recommended mechanism for securing access from GKE workloads to Google Cloud services in most cases. citeturn986975search15

## Identity flow

```text
Pod
 |
 | uses Kubernetes ServiceAccount
 v
GKE Workload Identity Pool
 |
 | authorized through IAM
 v
Google Cloud resource
```

## Why use it?

Without Workload Identity Federation, teams may:

- Create a service-account key.
- Store the JSON key in a Kubernetes Secret.
- Mount the key into the container.

That creates key-rotation and leakage risks.

With Workload Identity Federation:

- No long-lived JSON key is required.
- Access is based on workload identity.
- IAM permissions can be scoped to the Kubernetes ServiceAccount principal.
- Different workloads can receive different permissions.

---

## Workload Identity example

Suppose `hello-app` must read objects from a Cloud Storage bucket.

### Step 1: Enable Workload Identity Federation

During Standard cluster creation:

```bash
gcloud container clusters create "$CLUSTER_NAME" \
  --zone="$ZONE" \
  --workload-pool="${PROJECT_ID}.svc.id.goog" \
  --machine-type=e2-standard-2 \
  --num-nodes=2
```

For an existing cluster:

```bash
gcloud container clusters update "$CLUSTER_NAME" \
  --zone="$ZONE" \
  --workload-pool="${PROJECT_ID}.svc.id.goog"
```

### Step 2: Create Kubernetes ServiceAccount

```bash
kubectl create serviceaccount hello-ksa \
  --namespace=default
```

### Step 3: Grant the Kubernetes principal access

For direct principal-based IAM access:

```bash
gcloud storage buckets add-iam-policy-binding gs://BUCKET_NAME \
  --member="principal://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${PROJECT_ID}.svc.id.goog/subject/ns/default/sa/hello-ksa" \
  --role="roles/storage.objectViewer"
```

### Step 4: Use the Kubernetes ServiceAccount in the Deployment

```yaml
spec:
  template:
    spec:
      serviceAccountName: hello-ksa
      containers:
      - name: hello-app
        image: IMAGE_URI
```

### Least-privilege example

Do not give:

```text
roles/storage.admin
```

when the workload only needs:

```text
roles/storage.objectViewer
```

---

# Mini Lab 14: Configure HPA and observe scaling

## Objective

1. Deploy a CPU-consuming application.
2. Configure HPA.
3. Generate traffic.
4. Observe replicas increase.
5. Stop load.
6. Observe replicas decrease.

---

## Part A: Create a test namespace

```bash
kubectl create namespace autoscaling-lab
```

---

## Part B: Deploy a workload

Create `php-apache.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: php-apache
  namespace: autoscaling-lab
spec:
  replicas: 1
  selector:
    matchLabels:
      app: php-apache
  template:
    metadata:
      labels:
        app: php-apache
    spec:
      containers:
      - name: php-apache
        image: registry.k8s.io/hpa-example:latest
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: "200m"
            memory: "64Mi"
          limits:
            cpu: "500m"
            memory: "128Mi"
---
apiVersion: v1
kind: Service
metadata:
  name: php-apache
  namespace: autoscaling-lab
spec:
  selector:
    app: php-apache
  ports:
  - port: 80
    targetPort: 80
```

Apply:

```bash
kubectl apply -f php-apache.yaml
```

Verify:

```bash
kubectl get pods -n autoscaling-lab
kubectl get service -n autoscaling-lab
```

---

## Part C: Create HPA

```bash
kubectl autoscale deployment php-apache \
  --namespace=autoscaling-lab \
  --cpu-percent=50 \
  --min=1 \
  --max=10
```

Check:

```bash
kubectl get hpa -n autoscaling-lab
```

Initially, the metric may show:

```text
<unknown>/50%
```

Wait until metrics become available.

---

## Part D: Generate load

Run a temporary load generator:

```bash
kubectl run load-generator \
  --namespace=autoscaling-lab \
  --image=busybox:1.36 \
  --restart=Never \
  -- /bin/sh -c \
  "while sleep 0.01; do wget -q -O- http://php-apache; done"
```

Watch HPA:

```bash
kubectl get hpa \
  --namespace=autoscaling-lab \
  --watch
```

In a second terminal:

```bash
kubectl get pods \
  --namespace=autoscaling-lab \
  --watch
```

Inspect:

```bash
kubectl describe hpa php-apache \
  --namespace=autoscaling-lab
```

The HPA walkthrough demonstrates the same fundamental behavior: an HPA observes workload metrics and changes the Deployment’s replica count automatically. citeturn986975search19

---

## Part E: Observe node scaling

Check nodes:

```bash
kubectl get nodes
```

Check unscheduled Pods:

```bash
kubectl get pods -n autoscaling-lab
kubectl describe pod POD_NAME -n autoscaling-lab
```

When the existing nodes cannot schedule newly created Pods and node-pool autoscaling is enabled, GKE can increase the node count.

View the node pool:

```bash
gcloud container node-pools describe default-pool \
  --cluster="$CLUSTER_NAME" \
  --zone="$ZONE"
```

---

## Part F: Stop traffic

```bash
kubectl delete pod load-generator \
  --namespace=autoscaling-lab
```

Observe:

```bash
kubectl get hpa \
  --namespace=autoscaling-lab \
  --watch
```

Scale-down is intentionally slower because stabilization helps prevent rapid oscillation.

---

## Part G: HPA through the GUI

1. Go to **Kubernetes Engine → Workloads**.
2. Open the Deployment.
3. Select the scaling or autoscaling action.
4. Configure:
   - Minimum replicas: `1`
   - Maximum replicas: `10`
   - CPU target: `50%`
5. Save.
6. Open the workload’s metrics and revision details.
7. Generate traffic.
8. Observe:
   - CPU usage
   - Replica count
   - Pod creation
   - Events

Console wording can vary as GKE UI capabilities evolve, so confirm the generated HPA under the workload details or with:

```bash
kubectl get hpa -A
```

---

## Part H: Cleanup

Delete lab workload:

```bash
kubectl delete namespace autoscaling-lab
```

Delete application:

```bash
kubectl delete service hello-app-service
kubectl delete deployment hello-app
```

Delete cluster:

```bash
gcloud container clusters delete "$CLUSTER_NAME" \
  --zone="$ZONE"
```

Delete Artifact Registry repository:

```bash
gcloud artifacts repositories delete "$REPOSITORY" \
  --location="$REGION"
```

Check for remaining external addresses and load balancers:

```bash
gcloud compute addresses list
gcloud compute forwarding-rules list
```

---

# ACE exam decision table

| Requirement | Recommended choice |
|---|---|
| Store private Docker images | Artifact Registry Docker repository |
| Developer must upload images | Artifact Registry Writer |
| GKE only needs to pull images | Artifact Registry Reader |
| Minimum Kubernetes infrastructure management | GKE Autopilot |
| Need direct node-pool control | GKE Standard |
| Production control-plane resilience | Regional GKE cluster |
| Worker nodes must not have public IPs | Private nodes/private cluster |
| Private nodes need outbound internet | Cloud NAT |
| Expose application publicly | Service type `LoadBalancer`, Ingress, or Gateway |
| Expose application only inside cluster | `ClusterIP` Service |
| Maintain stable Pod identity and storage | StatefulSet |
| Scale Pod replicas based on CPU | HPA |
| Right-size Pod CPU and memory requests | VPA |
| Scale Standard-cluster nodes | Cluster autoscaler |
| Pod needs Google Cloud API access | Workload Identity Federation for GKE |
| Perform controlled 90/10 release | Weighted traffic splitting |
| Pod cannot pull image | Check image URI and node SA Artifact Registry Reader role |
| Pod remains Pending | Check resources, selectors, taints, PVC and autoscaling limits |
| Application restarts continuously | Inspect logs and `CrashLoopBackOff` events |

---

# ACE certification practice questions

## Question 1

A company builds Docker images in a CI/CD pipeline. The pipeline must push images to Artifact Registry but must not delete the repository or change repository settings. Which role should be granted?

A. Artifact Registry Reader  
B. Artifact Registry Writer  
C. Artifact Registry Administrator  
D. Kubernetes Engine Developer  

**Answer: B — Artifact Registry Writer**

The Writer role allows reading and uploading artifacts without granting full repository administration.

---

## Question 2

A GKE application cannot start. The Pod shows `ImagePullBackOff`, and its image is stored in a private Artifact Registry repository in the same project. What should you check first?

A. Whether the Pod has `roles/editor`  
B. Whether the node service account has Artifact Registry Reader  
C. Whether the Kubernetes Service is `LoadBalancer`  
D. Whether HPA is enabled  

**Answer: B**

Image pulling is performed using the relevant runtime/node identity. It needs read access to the repository.

---

## Question 3

A small application team wants to run Kubernetes workloads but does not want to configure machine types, node pools, node upgrades, or node autoscaling. Which GKE mode should it use?

A. Standard  
B. Autopilot  
C. Compute Engine managed instance group  
D. Cloud Functions  

**Answer: B — Autopilot**

Autopilot manages the underlying node infrastructure and provisions resources based on workload manifests.

---

## Question 4

A production application must remain manageable even if one zone in a region becomes unavailable. Which GKE cluster type is most appropriate?

A. Single zonal cluster  
B. Regional cluster  
C. Cloud Shell cluster  
D. Routes-based zonal cluster  

**Answer: B — Regional cluster**

Regional clusters provide a control plane replicated across zones and support multi-zone workload placement.

---

## Question 5

A security requirement states that GKE worker nodes must not have external IP addresses. The workloads still need outbound access to public package repositories. What should you configure?

A. Public nodes and firewall tags  
B. Private nodes and Cloud NAT  
C. A `NodePort` Service  
D. Workload Identity Federation only  

**Answer: B**

Cloud NAT provides outbound connectivity for resources that use private IP addresses without assigning public IPs to them.

---

## Question 6

An application should automatically increase from two to ten Pods when average CPU utilization exceeds its target. What should you configure?

A. Cluster autoscaler only  
B. Vertical Pod Autoscaler  
C. Horizontal Pod Autoscaler  
D. Managed instance group autoscaler  

**Answer: C — HPA**

HPA changes the number of Pod replicas based on metrics.

---

## Question 7

HPA has been configured using CPU utilization, but it shows an unknown target and does not scale properly. What is a likely missing configuration?

A. A public IP on every Pod  
B. CPU resource requests on the containers  
C. A StatefulSet  
D. Artifact Registry Writer access  

**Answer: B**

CPU percentage is measured relative to the configured CPU request.

---

## Question 8

A Standard cluster has several Pending Pods because no node has sufficient CPU. Node-pool autoscaling is enabled and has not reached its maximum. What should happen?

A. VPA deletes the cluster  
B. GKE adds nodes to the node pool  
C. Artifact Registry creates another repository  
D. Kubernetes converts the Pods into VMs  

**Answer: B**

The cluster autoscaler adds capacity when Pods are unschedulable because of insufficient node resources.

---

## Question 9

A database running in Kubernetes requires stable Pod names and a dedicated persistent volume for each replica. Which workload object should be used?

A. Deployment  
B. DaemonSet  
C. StatefulSet  
D. Job  

**Answer: C — StatefulSet**

StatefulSets provide stable identity and storage associations.

---

## Question 10

A frontend Pod must communicate with backend Pods using a stable internal endpoint. The backend must not be exposed outside the cluster. Which resource should be created?

A. Service of type `ClusterIP`  
B. Service of type `LoadBalancer`  
C. External IP address  
D. Cloud NAT gateway  

**Answer: A**

`ClusterIP` provides a stable virtual IP and DNS name that is reachable within the cluster.

---

## Question 11

A GKE workload must read objects from Cloud Storage. The security team prohibits downloading and storing service-account JSON keys. What should you configure?

A. A service-account key in a Kubernetes Secret  
B. Workload Identity Federation for GKE  
C. An external LoadBalancer Service  
D. Docker Hub credentials  

**Answer: B**

Workload Identity Federation provides short-lived, identity-based access without long-lived key files.

---

## Question 12

A team wants to route 95% of application traffic to version 1 and 5% to version 2. What deployment technique is being used?

A. Vertical scaling  
B. Canary traffic splitting  
C. Node auto-repair  
D. Stateful scheduling  

**Answer: B**

A small percentage is sent to the new version to verify its health before full rollout.

---

## Question 13

Which command configures Docker authentication for an Artifact Registry repository in `asia-south1`?

A.

```bash
kubectl auth configure-docker asia-south1
```

B.

```bash
gcloud auth configure-docker asia-south1-docker.pkg.dev
```

C.

```bash
docker login gke.googleapis.com
```

D.

```bash
gcloud container login asia-south1
```

**Answer: B**

---

## Question 14

A user tries to push:

```text
asia-south1-docker.pkg.dev/project-a/app:v1
```

but receives a repository-not-found error. What is wrong?

A. Artifact Registry does not support tags  
B. The path is missing the repository component  
C. Images must be pushed using `kubectl`  
D. Images must use a global location  

**Answer: B**

The path must be:

```text
LOCATION-docker.pkg.dev/PROJECT_ID/REPOSITORY/IMAGE:TAG
```

---

## Question 15

A Pod managed by a Deployment is manually deleted. What normally happens?

A. The Deployment is deleted  
B. The ReplicaSet creates a replacement Pod  
C. The GKE cluster is recreated  
D. The Service becomes a StatefulSet  

**Answer: B**

The controller continuously reconciles the actual state with the desired replica count.

---

## Question 16

A company needs different machine types for web applications and memory-intensive analytics workloads in one Standard cluster. What should it configure?

A. Multiple namespaces only  
B. Multiple node pools with labels and scheduling constraints  
C. Multiple Artifact Registry tags  
D. Multiple Cloud NAT gateways  

**Answer: B**

Separate node pools can use different machine types, labels, taints, service accounts and scaling configurations.

---

## Question 17

Which statement correctly describes VPA?

A. It provisions external load balancers  
B. It adjusts the number of Pods  
C. It recommends or modifies Pod CPU and memory requests  
D. It pushes images to Artifact Registry  

**Answer: C**

HPA changes replica count; VPA adjusts resource sizing.

---

## Question 18

You want to inspect why a Pod cannot be scheduled. Which command is most useful?

```bash
kubectl describe pod POD_NAME
```

The events section commonly shows:

- Insufficient CPU
- Insufficient memory
- Node selector mismatch
- Untolerated taint
- Unbound PVC

---

## Question 19

A GKE Service exists, but requests do not reach any Pods. Which configuration should you compare first?

A. Service selector and Pod labels  
B. Dockerfile `WORKDIR` and project name  
C. HPA maximum and Artifact Registry region  
D. Cloud NAT IP and image digest  

**Answer: A**

A Service routes to Pods selected through matching labels.

---

## Question 20

Which statement is correct?

A. HPA adds nodes and cluster autoscaler adds Pods  
B. HPA adds Pods and cluster autoscaler adds nodes  
C. VPA always adds Pods  
D. Artifact Registry performs node scaling  

**Answer: B**

---

# Important commands revision sheet

```bash
# Artifact Registry
gcloud artifacts repositories create REPO \
  --repository-format=docker \
  --location=REGION

gcloud auth configure-docker REGION-docker.pkg.dev

docker build -t app:v1 .

docker tag app:v1 \
  REGION-docker.pkg.dev/PROJECT_ID/REPO/app:v1

docker push \
  REGION-docker.pkg.dev/PROJECT_ID/REPO/app:v1

gcloud artifacts docker images list \
  REGION-docker.pkg.dev/PROJECT_ID/REPO \
  --include-tags
```

```bash
# GKE cluster
gcloud container clusters create CLUSTER \
  --zone=ZONE \
  --num-nodes=2 \
  --machine-type=e2-standard-2

gcloud container clusters get-credentials CLUSTER \
  --zone=ZONE

gcloud container clusters list
kubectl get nodes
kubectl get pods -A
kubectl get services -A
```

```bash
# Deployment and Service
kubectl create deployment hello-app \
  --image=IMAGE_URI

kubectl expose deployment hello-app \
  --type=LoadBalancer \
  --port=80 \
  --target-port=8080

kubectl get deployment
kubectl get pods
kubectl get service
```

```bash
# Scaling
kubectl scale deployment hello-app --replicas=3

kubectl autoscale deployment hello-app \
  --min=2 \
  --max=10 \
  --cpu-percent=60

kubectl get hpa
kubectl top pods
kubectl top nodes
```

```bash
# Troubleshooting
kubectl describe pod POD_NAME
kubectl logs POD_NAME
kubectl logs POD_NAME --previous
kubectl get events --sort-by=.metadata.creationTimestamp
kubectl rollout status deployment/hello-app
kubectl rollout history deployment/hello-app
kubectl rollout undo deployment/hello-app
```

---

# Official references

## Containers and Artifact Registry

- Google Cloud: Container concepts citeturn986975search29
- Google Cloud: Artifact Registry Docker quickstart citeturn986975search9
- Google Cloud: Push and pull images citeturn986975search0
- Google Cloud: Docker authentication citeturn986975search43
- Google Cloud: Artifact Registry access control citeturn600990search9
- Google Cloud: Artifact Registry troubleshooting citeturn986975search20
- Google Cloud: Deploying Artifact Registry images to GKE citeturn600990search18

## GKE basics

- Google Cloud: Install kubectl and configure access citeturn986975search7
- Google Cloud: GKE Autopilot overview citeturn986975search23
- Google Cloud: Autopilot and Standard comparison citeturn986975search37
- Google Cloud: Cluster configuration choices citeturn986975search13
- Google Cloud: GKE cluster and workload quickstart citeturn600990search8turn600990search12
- Google Cloud: Explore cluster and workloads citeturn600990search39
- Google Cloud: Expose applications using Services citeturn600990search2
- Google Cloud: GKE network isolation citeturn600990search34

## GKE operations

- Google Cloud: Cluster autoscaling citeturn986975search12
- Kubernetes: Horizontal Pod Autoscaling citeturn986975search8
- Kubernetes: HPA walkthrough citeturn986975search19
- Google Cloud: Vertical Pod Autoscaling citeturn986975search31
- Kubernetes: StatefulSets citeturn986975search46
- Google Cloud: Stateful applications on GKE citeturn600990search22
- Google Cloud: Workload Identity Federation for GKE citeturn986975search15
- Google Cloud: GKE Gateway traffic management citeturn600990search10
- Google Cloud: Weighted traffic splitting citeturn600990search0
