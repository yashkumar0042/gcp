Let's dive into more detailed steps for setting up a Google Kubernetes Engine (GKE) lab on Google Cloud Platform. In this lab, we'll deploy a basic web application using Kubernetes.

**Lab Objective:** Deploy a simple web application on Google Kubernetes Engine (GKE) using Kubernetes manifests.

### Step 1: Set Up Your Google Cloud Project

Ensure you have a Google Cloud Platform account and create a new project or use an existing one.

### Step 2: Enable the GKE API

Navigate to [APIs & Services > Dashboard](https://console.cloud.google.com/apis/dashboard) in the Google Cloud Console. Search for "Kubernetes Engine API" and enable it for your project.

### Step 3: Install and Configure Google Cloud SDK

Install the [Google Cloud SDK](https://cloud.google.com/sdk) on your local machine. Authenticate your account and set the default project:

```bash
gcloud auth login
gcloud config set project YOUR_PROJECT_ID
```

Replace `YOUR_PROJECT_ID` with your actual project ID.

### Step 4: Create a GKE Cluster

Create a GKE cluster named `my-gke-cluster` with three nodes in the `us-central1-a` zone:

```bash
gcloud container clusters create my-gke-cluster \
    --num-nodes=3 \
    --zone=us-central1-a
```

This command creates a GKE cluster with the specified configuration.

### Step 5: Configure `kubectl`

Configure `kubectl` to use the newly created GKE cluster:

```bash
gcloud container clusters get-credentials my-gke-cluster --zone=us-central1-a
```

This command fetches credentials for the specified GKE cluster and sets them as the default for `kubectl`.

### Step 6: Deploy a Simple Web Application

Create a Kubernetes Deployment by creating a file named `deployment.yaml` with the following content:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-web-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: my-web-app
  template:
    metadata:
      labels:
        app: my-web-app
    spec:
      containers:
      - name: my-web-app
        image: gcr.io/google-samples/hello-app:1.0
        ports:
        - containerPort: 8080
```

Apply the deployment configuration:

```bash
kubectl apply -f deployment.yaml
```

This deploys a simple web application with two replicas.

### Step 7: Expose the Web Application

Expose the web application to the internet:

```bash
kubectl expose deployment my-web-app --type=LoadBalancer --port=8080
```

This command creates a LoadBalancer service, providing an external IP to access the application.

### Step 8: Access the Web Application

Get the external IP address:

```bash
kubectl get service my-web-app
```

Open a web browser and navigate to the external IP address followed by port 8080. You should see the web application running.

### Step 9: Clean Up

After completing the lab, you can clean up resources to avoid charges:

```bash
gcloud container clusters delete my-gke-cluster --zone=us-central1-a
```

This example provides a more detailed walkthrough of setting up a GKE lab. Adjustments can be made based on your specific application and requirements.
