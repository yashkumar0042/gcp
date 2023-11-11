# Google Kubernetes Engine (GKE) Basics in GCP

## Components of GKE:

### 1. **Node Pools:**
   - **Functionality:** Node pools are groups of nodes within a cluster that have the same configuration. They allow you to manage the size and configuration of a group of nodes.
   - **Advantages:** Flexibility to configure nodes for specific workloads within the same cluster.
   - **CLI Command:**
     ```bash
     gcloud container node-pools create NAME --cluster=CLUSTER_NAME --machine-type=MACHINE_TYPE
     ```

### 2. **Pods:**
   - **Functionality:** Pods are the smallest deployable units in Kubernetes, representing a single instance of a running process in a cluster.
   - **Advantages:** Facilitates the co-location of tightly coupled application components.
   - **CLI Command:**
     ```bash
     kubectl run NAME --image=IMAGE
     ```

### 3. **Services:**
   - **Functionality:** Kubernetes Service is an abstraction that defines a logical set of Pods and a policy by which to access them. It enables load balancing and service discovery.
   - **Advantages:** Allows stable network access to a set of Pods, abstracting Pod IP changes.
   - **CLI Command:**
     ```bash
     kubectl expose deployment NAME --port=PORT --target-port=TARGET_PORT --type=TYPE
     ```

### 4. **Deployments:**
   - **Functionality:** A Deployment allows you to describe a desired state for your application and provides declarative updates to applications.
   - **Advantages:** Simplifies the management of replica sets and Pods.
   - **CLI Command:**
     ```bash
     kubectl create deployment NAME --image=IMAGE
     ```

### 5. **ConfigMaps:**
   - **Functionality:** ConfigMaps allow you to decouple configuration artifacts from container images, keeping containerized applications portable.
   - **Advantages:** Centralized management of configuration settings.
   - **CLI Command:**
     ```bash
     kubectl create configmap NAME --from-literal=key1=value1 --from-literal=key2=value2
     ```

## Functionality of Each Component:

1. **Node Pools:**
   - **Functionality:** Node pools provide a way to separate workloads within a cluster based on resource requirements, enabling better resource utilization.

2. **Pods:**
   - **Functionality:** Pods represent a logical unit of deployment in Kubernetes, encapsulating one or more containers and shared resources.

3. **Services:**
   - **Functionality:** Services provide network abstraction to expose applications within the cluster or to the external world. They enable load balancing and service discovery.

4. **Deployments:**
   - **Functionality:** Deployments enable declarative updates and scaling of applications. They ensure the desired state of the application and manage the creation and scaling of replica sets.

5. **ConfigMaps:**
   - **Functionality:** ConfigMaps separate configuration data from application code, promoting flexibility and ease of configuration changes without modifying container images.

## Advantages of GKE Components:

1. **Node Pools:**
   - **Advantages:** Flexibility in managing node configurations, optimizing resources based on workload requirements.

2. **Pods:**
   - **Advantages:** Encapsulation of containers, facilitating efficient resource sharing and communication.

3. **Services:**
   - **Advantages:** Load balancing and service discovery simplify network access to applications.

4. **Deployments:**
   - **Advantages:** Declarative updates and scaling ensure application reliability and availability.

5. **ConfigMaps:**
   - **Advantages:** Separation of configuration data from code, promoting maintainability and portability.

## Use Cases:

1. **Node Pools:**
   - **Use Cases:** Varied workloads with different resource requirements running within the same cluster.

2. **Pods:**
   - **Use Cases:** Microservices architecture, enabling the development of loosely coupled, independently deployable services.

3. **Services:**
   - **Use Cases:** Load balancing and exposing applications to external users or other applications within the cluster.

4. **Deployments:**
   - **Use Cases:** Rolling updates, rollback mechanisms, and scaling applications horizontally.

5. **ConfigMaps:**
   - **Use Cases:** Centralized management of configuration data for applications running in containers.

# Sample GKE Lab

## Lab Objective: Deploy a simple web application on GKE.

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

### Step 4: Create a GKE Cluster

Create a GKE cluster named `my-gke-cluster`:

```bash
gcloud container clusters create my-gke-cluster --num-nodes=3 --zone=us-central1-a
```

### Step 5: Configure `kubectl`

Configure `kubectl` to use the newly created GKE cluster:

```bash
gcloud container clusters get-credentials my-gke-cluster --zone=us-central1-a
```

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

### Step 7: Expose the Web Application

Expose the web application to the internet:

```bash
kubectl expose deployment my-web-app --type=LoadBalancer --port=8080
```

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

This example provides a detailed walkthrough of setting up a GKE lab, including components, functionality, advantages, use cases, and CLI commands. Adjustments can be made based on your specific application and requirements.
