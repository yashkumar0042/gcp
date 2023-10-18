# Deploying and Implementing Google Kubernetes Engine Resources

In this comprehensive guide, we will delve into the technical aspects of deploying and implementing Google Kubernetes Engine (GKE) resources. Google Kubernetes Engine is a managed Kubernetes service that simplifies the deployment, management, and scaling of containerized applications using Kubernetes. We will cover the following tasks in detail:

1. Installing and Configuring the Command Line Interface (CLI) for Kubernetes (kubectl)
2. Deploying a Google Kubernetes Engine Cluster
   - AutoPilot Mode
   - Regional Clusters
   - Private Clusters
3. Deploying a Containerized Application to Google Kubernetes Engine
4. Configuring Google Kubernetes Engine Monitoring and Logging

## 1. Installing and Configuring kubectl

### 1.1 Prerequisites

Before installing `kubectl`, ensure you have the following prerequisites in place:

- Google Cloud Platform (GCP) account with billing enabled.
- Google Cloud SDK (`gcloud`) installed and authenticated.
- Access to a GKE cluster (either existing or to be created).

### 1.2 Installing kubectl

To install `kubectl`, you can use `gcloud` which comes as part of the Google Cloud SDK. Follow these steps:

1. Update `gcloud` components to ensure you have the latest version:

   ```bash
   gcloud components update
   ```

2. Install `kubectl` using `gcloud`:

   ```bash
   gcloud components install kubectl
   ```

3. Verify the installation by checking the version of `kubectl`:

   ```bash
   kubectl version --client
   ```

### 1.3 Configuring kubectl

To configure `kubectl` to work with your GKE clusters, you need to set up credentials and contexts. Follow these steps:

1. Authenticate `gcloud`:

   ```bash
   gcloud auth login
   ```

   Follow the prompts to log in with your GCP account.

2. Configure `kubectl` to use the credentials for a specific GKE cluster:

   ```bash
   gcloud container clusters get-credentials CLUSTER_NAME --zone ZONE --project PROJECT_ID
   ```

   Replace `CLUSTER_NAME`, `ZONE`, and `PROJECT_ID` with your specific cluster details.

3. Verify that `kubectl` is configured correctly by checking the cluster information:

   ```bash
   kubectl cluster-info
   ```

Now, `kubectl` is set up and ready to interact with your GKE cluster.

## 2. Deploying a Google Kubernetes Engine Cluster

### 2.1 AutoPilot Mode

AutoPilot mode is a fully managed GKE mode that abstracts the underlying infrastructure and simplifies cluster management.

#### 2.1.1 Creating an AutoPilot Cluster

To create an AutoPilot GKE cluster, use the following command:

```bash
gcloud container clusters create-auto CLUSTER_NAME --region REGION
```

Replace `CLUSTER_NAME` with your desired cluster name and `REGION` with the desired region for your cluster. AutoPilot clusters automatically handle node management, scaling, and repair.

### 2.2 Regional Clusters

Regional clusters are designed for high availability by distributing nodes across multiple zones within a region.

#### 2.2.1 Creating a Regional Cluster

To create a regional GKE cluster, use the following command:

```bash
gcloud container clusters create CLUSTER_NAME --region REGION
```

Replace `CLUSTER_NAME` with your desired cluster name and `REGION` with the desired region.

### 2.3 Private Clusters

Private clusters restrict public access to your GKE nodes and control plane.

#### 2.3.1 Creating a Private Cluster

To create a private GKE cluster, use the following command:

```bash
gcloud container clusters create CLUSTER_NAME --private-cluster --region REGION
```

Replace `CLUSTER_NAME` with your desired cluster name, `REGION` with the desired region, and `--private-cluster` enables private cluster mode.

## 3. Deploying a Containerized Application to Google Kubernetes Engine

Now that you have a GKE cluster, you can deploy containerized applications to it. Here are the steps:

### 3.1 Prepare Your Application

Ensure your application is containerized using a containerization tool like Docker. Create a Docker image of your application and push it to a container registry, such as Google Container Registry (GCR).

### 3.2 Deploy Your Application

Use Kubernetes manifests (YAML files) to define the deployment, services, and other resources required for your application. Apply these manifests to your GKE cluster using `kubectl`.

```bash
kubectl apply -f your-application.yaml
```

Replace `your-application.yaml` with the path to your Kubernetes manifest file.

### 3.3 Expose Your Application

To expose your application to the internet or within your cluster, create a Kubernetes Service of type `LoadBalancer` or `NodePort`.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: your-service
spec:
  type: LoadBalancer  # or NodePort
  ports:
    - port: 80
      targetPort: 8080  # Replace with your application's port
  selector:
    app: your-app-label  # Replace with your application's label
```

Apply this service manifest using `kubectl apply -f your-service.yaml`.

Your application should now be accessible via the LoadBalancer's external IP or the NodePort.

## 4. Configuring Google Kubernetes Engine Monitoring and Logging

Configuring monitoring and logging in GKE is crucial for observability and troubleshooting. Here's how you can set up these components:

### 4.1 Monitoring

Google Cloud Monitoring allows you to collect and view metrics from your GKE clusters and applications.

#### 4.1.1 Enabling Monitoring for Your Cluster

```bash
gcloud container clusters update CLUSTER_NAME --update-addons=Monitoring=ENABLED --region REGION
```

Replace `CLUSTER_NAME` with your cluster name and `REGION` with the region.

#### 4.1.2 Creating Custom Metrics and Alerts

You can create custom metrics and alerts using Cloud Monitoring. Use `kubectl` to export custom metrics from your application and set up alerting policies in the Google Cloud Console.

### 4.2 Logging

Google Cloud Logging allows you to centralize and analyze logs from your GKE clusters and applications.

#### 4.2.1 Enabling Logging for Your Cluster

```bash
gcloud container clusters update CLUSTER_NAME --update-addons=Logging=ENABLED --region REGION
```

Replace `CLUSTER_NAME` with your cluster name and `REGION` with the region.

#### 4.2.2 Exporting Application Logs

You can configure your application to send logs to Google Cloud Logging by using one of the supported logging libraries or agents. For example, you can use Fluentd or the Cloud Logging agent to export logs.

### 4.2.3 Viewing Logs

You can view logs in the Google Cloud Console or use tools like `gcloud` or `kubectl` to access logs from the command line.

#### Viewing Container Logs

To view logs from a specific container in a pod:

```bash
kubectl logs POD_NAME -c CONTAINER_NAME
```

Replace `POD_NAME` with the name of the pod and `CONTAINER_NAME` with the name of the container.

These detailed technical notes cover the process of deploying and implementing Google Kubernetes Engine resources, including installing `kubectl`, creating different types of GKE clusters, deploying containerized applications, and configuring monitoring and logging. Following these steps and commands will help you effectively manage and monitor your containerized applications in GKE.

# LAB - GKE
Walk through the process of deploying a sample containerized application on Google Kubernetes Engine (GKE) from scratch. We'll start with creating the application, containerizing it, pushing the image to Google Container Registry (GCR), setting up a GKE cluster, and deploying the application to the cluster.

## Step 1: Create a Sample Application

For this example, we'll use a simple Python web application. You can choose any application you prefer. Here's a basic "Hello World" Python application:

**app.py:**
```python
from flask import Flask

app = Flask(__name__)

@app.route('/')
def hello_world():
    return 'Hello, GKE!'
```

**requirements.txt:**
```
Flask==2.1.1
```

## Step 2: Create a Dockerfile

Next, create a Dockerfile to containerize your application. The Dockerfile defines how your application will be packaged into a container image.

**Dockerfile:**
```Dockerfile
# Use the official Python image
FROM python:3.8-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# Create and set the working directory
WORKDIR /app

# Copy the application code and requirements.txt
COPY app.py /app/
COPY requirements.txt /app/

# Install Python dependencies
RUN pip install -r requirements.txt

# Expose the port your application will run on
EXPOSE 5000

# Define the command to run your application
CMD ["python", "app.py"]
```

## Step 3: Build and Push the Docker Image to GCR

Now, build your Docker image and push it to Google Container Registry (GCR) so that GKE can access it.

Assuming you have Docker installed locally:

```bash
# Build the Docker image (replace GCR_IMAGE_NAME and TAG with your image name and version)
docker build -t gcr.io/YOUR_PROJECT_ID/GCR_IMAGE_NAME:TAG .

# Authenticate Docker to your GCR (assuming you are already authenticated to GCP)
gcloud auth configure-docker

# Push the Docker image to GCR
docker push gcr.io/YOUR_PROJECT_ID/GCR_IMAGE_NAME:TAG
```

## Step 4: Set Up a GKE Cluster

Create a GKE cluster where you'll deploy your application. You can do this through the Google Cloud Console or using the `gcloud` command-line tool.

### Using `gcloud`:

```bash
# Create a GKE cluster (replace CLUSTER_NAME with your desired name)
gcloud container clusters create CLUSTER_NAME \
    --num-nodes=3 \
    --machine-type=n1-standard-2 \
    --zone=us-central1-a
```

This command creates a GKE cluster with three nodes of the specified machine type in the `us-central1-a` zone. Adjust these parameters according to your requirements.

### Configure `kubectl` to Use the Cluster

To interact with your GKE cluster using `kubectl`, configure it to use the credentials for your newly created cluster:

```bash
# Fetch credentials for the cluster (replace CLUSTER_NAME with your cluster name)
gcloud container clusters get-credentials CLUSTER_NAME --zone=us-central1-a
```

## Step 5: Deploy Your Application

Now that you have a GKE cluster, deploy your application using Kubernetes manifests. Here's a simple deployment manifest for your application:

**deployment.yaml:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: YOUR_APP_NAME
spec:
  replicas: 3
  selector:
    matchLabels:
      app: YOUR_APP_NAME
  template:
    metadata:
      labels:
        app: YOUR_APP_NAME
    spec:
      containers:
      - name: YOUR_APP_NAME
        image: gcr.io/YOUR_PROJECT_ID/GCR_IMAGE_NAME:TAG
        ports:
        - containerPort: 5000
```

Replace `YOUR_APP_NAME`, `YOUR_PROJECT_ID`, `GCR_IMAGE_NAME`, and `TAG` with your application's details.

Apply the deployment:

```bash
kubectl apply -f deployment.yaml
```

This command deploys three replicas of your application.

## Step 6: Expose Your Application

To make your application accessible from the internet, you can use a Kubernetes Service with a LoadBalancer. Create a service manifest:

**service.yaml:**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: YOUR_APP_NAME-service
spec:
  selector:
    app: YOUR_APP_NAME
  ports:
    - protocol: TCP
      port: 80
      targetPort: 5000
  type: LoadBalancer
```

Apply the service:

```bash
kubectl apply -f service.yaml
```

This creates a LoadBalancer service that exposes your application on port 80.

## Step 7: Access Your Application

To access your application, find the external IP address assigned to the LoadBalancer service:

```bash
kubectl get svc
```

Look for the `EXTERNAL-IP` of your service. It may take a moment for the IP to be assigned.

Once you have the external IP, open a web browser and navigate to it. You should see your "Hello, GKE!" application.

Congratulations! You've successfully deployed a containerized application to Google Kubernetes Engine from scratch. This guide covers the entire process, from creating the application code to accessing it via a LoadBalancer service in GKE.
