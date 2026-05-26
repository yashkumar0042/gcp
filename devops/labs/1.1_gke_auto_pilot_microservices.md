# GKE Autopilot Microservices Demo

This guide shows how to create a **GKE Autopilot cluster** and deploy a simple website with multiple microservices.

The demo includes:

- A public **frontend website** running on nginx
- An internal **users microservice**
- An internal **orders microservice**
- Service-to-service communication inside Kubernetes
- Public access using a Kubernetes `LoadBalancer` Service
- Basic scaling, logs, debugging, and cleanup commands

---

## Architecture

```text
Internet
   ↓
Google Cloud external Load Balancer
   ↓
frontend-service  ← public LoadBalancer
   ↓
frontend pod: nginx
   ├── /api/users  → users-service   ← internal ClusterIP
   └── /api/orders → orders-service  ← internal ClusterIP
                         ↓
                    calls users-service internally
```

GKE Autopilot is the managed/automatic mode of GKE where Google manages the node infrastructure, scaling, and many operational concerns. You mainly focus on Kubernetes manifests.

---

## 0. Prerequisites

Install the required CLI tools:

```bash
gcloud version
kubectl version --client
```

Login to Google Cloud:

```bash
gcloud auth login
```

Set your project, region, and cluster name:

```bash
export PROJECT_ID="your-gcp-project-id"
export REGION="asia-south1"
export CLUSTER_NAME="demo-gke-autopilot"

gcloud config set project $PROJECT_ID
gcloud config set compute/region $REGION
```

Enable required APIs:

```bash
gcloud services enable container.googleapis.com
gcloud services enable compute.googleapis.com
```

Check your active configuration:

```bash
gcloud config list
```

---

## 1. Create GKE Autopilot Cluster

Create the cluster:

```bash
gcloud container clusters create-auto $CLUSTER_NAME \
  --region $REGION
```

This creates a **regional GKE Autopilot cluster**.

Get cluster credentials:

```bash
gcloud container clusters get-credentials $CLUSTER_NAME \
  --region $REGION \
  --project $PROJECT_ID
```

Verify access:

```bash
kubectl get nodes
kubectl get ns
```

In Autopilot, you do not create or manage node pools manually. GKE manages the node infrastructure for you.

---

## 2. Create Project Folder

```bash
mkdir gke-microservices-demo
cd gke-microservices-demo
```

---

## 3. Create Namespace

Create the namespace manifest:

```bash
cat > 00-namespace.yaml <<'EOF'
apiVersion: v1
kind: Namespace
metadata:
  name: micro-demo
EOF
```

Apply it:

```bash
kubectl apply -f 00-namespace.yaml
```

---

## 4. Users Microservice

The `users-service` is an internal backend service.

It exposes:

```text
/users
/health
```

Create the manifest:

```bash
cat > 01-users-service.yaml <<'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: users-app-code
  namespace: micro-demo
data:
  app.py: |
    from flask import Flask, jsonify

    app = Flask(__name__)

    @app.route("/")
    def home():
        return jsonify({
            "service": "users-service",
            "message": "Users service is running on GKE Autopilot"
        })

    @app.route("/users")
    def users():
        return jsonify({
            "service": "users-service",
            "users": [
                {"id": 1, "name": "Tushar"},
                {"id": 2, "name": "Aman"},
                {"id": 3, "name": "Ravi"}
            ]
        })

    @app.route("/health")
    def health():
        return jsonify({"status": "ok"})

    if __name__ == "__main__":
        app.run(host="0.0.0.0", port=5000)
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: users-deployment
  namespace: micro-demo
spec:
  replicas: 2
  selector:
    matchLabels:
      app: users
  template:
    metadata:
      labels:
        app: users
    spec:
      containers:
        - name: users
          image: python:3.12-slim
          command: ["/bin/sh", "-c"]
          args:
            - pip install flask && python /app/app.py
          ports:
            - containerPort: 5000
          volumeMounts:
            - name: users-code
              mountPath: /app
          resources:
            requests:
              cpu: "250m"
              memory: "256Mi"
            limits:
              cpu: "500m"
              memory: "512Mi"
      volumes:
        - name: users-code
          configMap:
            name: users-app-code
---
apiVersion: v1
kind: Service
metadata:
  name: users-service
  namespace: micro-demo
spec:
  type: ClusterIP
  selector:
    app: users
  ports:
    - port: 5000
      targetPort: 5000
EOF
```

Apply it:

```bash
kubectl apply -f 01-users-service.yaml
```

---

## 5. Orders Microservice

The `orders-service` is another internal backend service.

It exposes:

```text
/orders
/health
```

It also calls the users service internally using:

```text
http://users-service:5000/users
```

Create the manifest:

```bash
cat > 02-orders-service.yaml <<'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: orders-app-code
  namespace: micro-demo
data:
  app.py: |
    from flask import Flask, jsonify
    import requests

    app = Flask(__name__)

    USERS_SERVICE_URL = "http://users-service:5000/users"

    @app.route("/")
    def home():
        return jsonify({
            "service": "orders-service",
            "message": "Orders service is running on GKE Autopilot"
        })

    @app.route("/orders")
    def orders():
        try:
            users_response = requests.get(USERS_SERVICE_URL, timeout=2)
            users_data = users_response.json()
        except Exception as e:
            users_data = {
                "error": "Could not call users-service",
                "details": str(e)
            }

        return jsonify({
            "service": "orders-service",
            "orders": [
                {"order_id": 101, "item": "Helmet", "user_id": 1},
                {"order_id": 102, "item": "Riding Gloves", "user_id": 2},
                {"order_id": 103, "item": "Bike Jacket", "user_id": 3}
            ],
            "internal_call_to_users_service": users_data
        })

    @app.route("/health")
    def health():
        return jsonify({"status": "ok"})

    if __name__ == "__main__":
        app.run(host="0.0.0.0", port=5000)
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: orders-deployment
  namespace: micro-demo
spec:
  replicas: 2
  selector:
    matchLabels:
      app: orders
  template:
    metadata:
      labels:
        app: orders
    spec:
      containers:
        - name: orders
          image: python:3.12-slim
          command: ["/bin/sh", "-c"]
          args:
            - pip install flask requests && python /app/app.py
          ports:
            - containerPort: 5000
          volumeMounts:
            - name: orders-code
              mountPath: /app
          resources:
            requests:
              cpu: "250m"
              memory: "256Mi"
            limits:
              cpu: "500m"
              memory: "512Mi"
      volumes:
        - name: orders-code
          configMap:
            name: orders-app-code
---
apiVersion: v1
kind: Service
metadata:
  name: orders-service
  namespace: micro-demo
spec:
  type: ClusterIP
  selector:
    app: orders
  ports:
    - port: 5000
      targetPort: 5000
EOF
```

Apply it:

```bash
kubectl apply -f 02-orders-service.yaml
```

---

## 6. Frontend Website

The frontend runs nginx.

It exposes a simple web page and proxies API calls:

```text
/api/users  → users-service:5000/users
/api/orders → orders-service:5000/orders
```

Create the manifest:

```bash
cat > 03-frontend.yaml <<'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: frontend-html
  namespace: micro-demo
data:
  index.html: |
    <!DOCTYPE html>
    <html>
    <head>
      <title>GKE Autopilot Microservices Demo</title>
      <style>
        body {
          font-family: Arial, sans-serif;
          background: #f5f7fb;
          margin: 0;
          padding: 40px;
        }
        .container {
          max-width: 900px;
          margin: auto;
          background: white;
          padding: 30px;
          border-radius: 16px;
          box-shadow: 0 8px 24px rgba(0,0,0,0.08);
        }
        h1 {
          color: #111827;
        }
        button {
          padding: 12px 20px;
          margin: 8px;
          border: none;
          border-radius: 8px;
          background: #2563eb;
          color: white;
          cursor: pointer;
          font-size: 15px;
        }
        button:hover {
          background: #1d4ed8;
        }
        pre {
          background: #111827;
          color: #22c55e;
          padding: 20px;
          border-radius: 12px;
          overflow-x: auto;
        }
        .box {
          margin-top: 20px;
          padding: 16px;
          background: #eef2ff;
          border-radius: 12px;
        }
      </style>
    </head>
    <body>
      <div class="container">
        <h1>GKE Autopilot Microservices Demo</h1>
        <p>This website is running on Kubernetes using GKE Autopilot.</p>

        <div class="box">
          <p><b>Architecture:</b></p>
          <p>Browser → Google Cloud Load Balancer → Frontend nginx → Internal Kubernetes Services → Backend Pods</p>
        </div>

        <button onclick="callUsers()">Call Users Service</button>
        <button onclick="callOrders()">Call Orders Service</button>

        <h2>Response</h2>
        <pre id="output">Click a button to call backend microservices...</pre>
      </div>

      <script>
        async function callUsers() {
          const res = await fetch('/api/users');
          const data = await res.json();
          document.getElementById('output').textContent = JSON.stringify(data, null, 2);
        }

        async function callOrders() {
          const res = await fetch('/api/orders');
          const data = await res.json();
          document.getElementById('output').textContent = JSON.stringify(data, null, 2);
        }
      </script>
    </body>
    </html>
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: frontend-nginx-config
  namespace: micro-demo
data:
  default.conf: |
    server {
      listen 80;

      location / {
        root /usr/share/nginx/html;
        index index.html;
      }

      location /api/users {
        proxy_pass http://users-service:5000/users;
      }

      location /api/orders {
        proxy_pass http://orders-service:5000/orders;
      }
    }
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend-deployment
  namespace: micro-demo
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
        - name: frontend
          image: nginx:1.27-alpine
          ports:
            - containerPort: 80
          volumeMounts:
            - name: frontend-html-volume
              mountPath: /usr/share/nginx/html
            - name: frontend-nginx-config-volume
              mountPath: /etc/nginx/conf.d
          resources:
            requests:
              cpu: "250m"
              memory: "256Mi"
            limits:
              cpu: "500m"
              memory: "512Mi"
      volumes:
        - name: frontend-html-volume
          configMap:
            name: frontend-html
        - name: frontend-nginx-config-volume
          configMap:
            name: frontend-nginx-config
---
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
  namespace: micro-demo
spec:
  type: LoadBalancer
  selector:
    app: frontend
  ports:
    - port: 80
      targetPort: 80
EOF
```

Apply it:

```bash
kubectl apply -f 03-frontend.yaml
```

In GKE, a Kubernetes Service of type `LoadBalancer` creates a Google Cloud external Load Balancer for external access.

---

## 7. Check Everything

```bash
kubectl get pods -n micro-demo
kubectl get svc -n micro-demo
kubectl get deployments -n micro-demo
```

Wait for deployments:

```bash
kubectl wait --for=condition=available deployment/users-deployment -n micro-demo --timeout=300s
kubectl wait --for=condition=available deployment/orders-deployment -n micro-demo --timeout=300s
kubectl wait --for=condition=available deployment/frontend-deployment -n micro-demo --timeout=300s
```

Get the public IP:

```bash
kubectl get svc frontend-service -n micro-demo
```

Example output:

```text
NAME               TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)
frontend-service   LoadBalancer   34.x.x.x        35.x.x.x         80:xxxxx/TCP
```

Open the website:

```text
http://<EXTERNAL-IP>
```

Example:

```text
http://35.200.100.50
```

---

## 8. Test APIs Using curl

Get Load Balancer IP:

```bash
export LB_IP=$(kubectl get svc frontend-service -n micro-demo -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

echo $LB_IP
```

Test frontend:

```bash
curl http://$LB_IP
```

Test users API:

```bash
curl http://$LB_IP/api/users
```

Test orders API:

```bash
curl http://$LB_IP/api/orders
```

In `/api/orders`, you should see that `orders-service` calls `users-service` internally.

---

## 9. Understand Service Communication

Inside Kubernetes, services communicate using DNS names.

Because all services are in the same namespace, these URLs work:

```text
http://users-service:5000/users
http://orders-service:5000/orders
```

Full DNS names:

```text
http://users-service.micro-demo.svc.cluster.local:5000/users
http://orders-service.micro-demo.svc.cluster.local:5000/orders
```

Frontend to users flow:

```text
Browser
  ↓
frontend-service LoadBalancer
  ↓
frontend pod nginx
  ↓
users-service ClusterIP
  ↓
users pods
```

Frontend to orders to users flow:

```text
Browser
  ↓
frontend-service LoadBalancer
  ↓
frontend pod nginx
  ↓
orders-service ClusterIP
  ↓
orders pods
  ↓
users-service ClusterIP
  ↓
users pods
```

---

## 10. Scale Microservices

Scale users service:

```bash
kubectl scale deployment users-deployment -n micro-demo --replicas=4
```

Scale orders service:

```bash
kubectl scale deployment orders-deployment -n micro-demo --replicas=3
```

Check pods:

```bash
kubectl get pods -n micro-demo -o wide
```

Kubernetes Service will automatically distribute traffic across the matching pods.

---

## 11. Check Logs

Frontend logs:

```bash
kubectl logs -n micro-demo deployment/frontend-deployment
```

Users logs:

```bash
kubectl logs -n micro-demo deployment/users-deployment
```

Orders logs:

```bash
kubectl logs -n micro-demo deployment/orders-deployment
```

Follow orders logs live:

```bash
kubectl logs -n micro-demo deployment/orders-deployment -f
```

---

## 12. Debug Inside the Cluster

Run a temporary curl pod:

```bash
kubectl run curl-test \
  -n micro-demo \
  --image=curlimages/curl \
  --rm -it \
  -- sh
```

Inside the pod:

```bash
curl http://users-service:5000/users
curl http://orders-service:5000/orders
exit
```

This proves that internal microservice communication is working.

---

## 13. Optional: Create HPA Autoscaling

For real workloads, you can use Horizontal Pod Autoscaler.

Create HPA for users service:

```bash
kubectl autoscale deployment users-deployment \
  -n micro-demo \
  --cpu-percent=60 \
  --min=2 \
  --max=5
```

Create HPA for orders service:

```bash
kubectl autoscale deployment orders-deployment \
  -n micro-demo \
  --cpu-percent=60 \
  --min=2 \
  --max=5
```

Check HPA:

```bash
kubectl get hpa -n micro-demo
```

In GKE Autopilot, you do not manually manage node scaling. GKE handles infrastructure scaling underneath while Kubernetes handles pod-level scaling based on your manifests and autoscaling configuration.

---

## 14. Recommended Real Infrastructure on GKE Autopilot

For this demo, `Service type LoadBalancer` is enough.

For a real production microservices app, use this:

| Layer | Recommended GCP setup |
|---|---|
| Cluster | GKE Autopilot |
| Public entry | GKE Ingress / Gateway API / LoadBalancer Service |
| Frontend | Deployment + Service |
| Backend microservices | Deployment + internal ClusterIP Services |
| Config | ConfigMap |
| Secrets | Secret Manager + External Secrets Operator |
| Database | Cloud SQL PostgreSQL / AlloyDB |
| Cache | Memorystore Redis |
| Container registry | Artifact Registry |
| CI/CD | Cloud Build / GitHub Actions / Argo CD |
| Observability | Cloud Logging, Cloud Monitoring, Managed Prometheus |
| TLS | Google-managed certificate |
| DNS | Cloud DNS |
| Security | Workload Identity Federation for GKE |
| Autoscaling | HPA + GKE Autopilot infrastructure scaling |

For production HTTP routing, prefer **Ingress** or **Gateway API** instead of exposing many `LoadBalancer` services.

Use one public entry point and route internally to services.

---

## 15. Delete Everything to Avoid Cost

Delete the app:

```bash
kubectl delete namespace micro-demo
```

Delete the GKE Autopilot cluster:

```bash
gcloud container clusters delete $CLUSTER_NAME \
  --region $REGION
```

Confirm:

```bash
gcloud container clusters list
```

---

## Full One-Shot Command Summary

```bash
export PROJECT_ID="your-gcp-project-id"
export REGION="asia-south1"
export CLUSTER_NAME="demo-gke-autopilot"

gcloud auth login
gcloud config set project $PROJECT_ID
gcloud config set compute/region $REGION

gcloud services enable container.googleapis.com
gcloud services enable compute.googleapis.com

gcloud container clusters create-auto $CLUSTER_NAME \
  --region $REGION

gcloud container clusters get-credentials $CLUSTER_NAME \
  --region $REGION \
  --project $PROJECT_ID

kubectl get nodes
```

Apply the YAML files:

```bash
kubectl apply -f 00-namespace.yaml
kubectl apply -f 01-users-service.yaml
kubectl apply -f 02-orders-service.yaml
kubectl apply -f 03-frontend.yaml
```

Get the public IP:

```bash
kubectl get svc frontend-service -n micro-demo
```

Open:

```text
http://<EXTERNAL-IP>
```

Final cleanup:

```bash
kubectl delete namespace micro-demo

gcloud container clusters delete $CLUSTER_NAME \
  --region $REGION
```
