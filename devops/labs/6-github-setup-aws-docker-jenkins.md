Below is a complete beginner-friendly setup for:

**GitHub push → GitHub webhook → Jenkins on EC2 → Docker build → Amazon ECR → Kubernetes/EKS deployment**

I’ll use these sample values throughout:

```text
AWS Account ID:      123456789012
AWS Region:          ap-south-1
EKS Cluster:         dev-eks-cluster
ECR Repository:      demo-app
Kubernetes Namespace: dev
Deployment Name:     demo-app
Container Name:      demo-app
Git Branch:          dev
Sample BUILD_NUMBER: 42
Sample Image Tag:    dev-42
```

Replace the sample values with your actual details.

---

# 1. Final architecture

```text
Developer
   |
   | git push origin dev
   v
GitHub Repository
   |
   | GitHub Webhook
   v
Jenkins on EC2
   |
   | 1. Checkout code
   | 2. Run tests
   | 3. Build Docker image
   | 4. Tag image as dev-${BUILD_NUMBER}
   | 5. Push image to ECR
   | 6. Update Kubernetes Deployment
   v
Amazon ECR
   |
   v
Amazon EKS / Kubernetes
   |
   v
Application Pods
```

For build number `42`, Jenkins will create:

```text
123456789012.dkr.ecr.ap-south-1.amazonaws.com/demo-app:dev-42
```

Using a unique immutable image tag such as `dev-42` is preferable to repeatedly using `latest`, because Kubernetes can clearly detect the image change and rollback history remains meaningful.

---

# 2. Prerequisites

You should already have:

* Jenkins installed and running on EC2
* A GitHub repository
* An Amazon ECR repository
* A Kubernetes or EKS cluster
* Jenkins EC2 network access to the Kubernetes API
* Jenkins EC2 network access to GitHub and ECR
* A public Jenkins URL reachable by GitHub

Example Jenkins URL:

```text
https://jenkins.example.com
```

The GitHub webhook URL will be:

```text
https://jenkins.example.com/github-webhook/
```

The trailing `/` is important.

---

# 3. Check Jenkins EC2 security group

The Jenkins EC2 security group should generally allow:

```text
Port 22    From your office/home IP only
Port 8080  From your IP or load balancer only
Port 443   From internet, if Jenkins is exposed through HTTPS
```

Recommended production-style setup:

```text
Internet
   |
   v
Application Load Balancer / Nginx
   |
   | HTTPS 443
   v
Jenkins EC2:8080
```

Avoid exposing Jenkins port `8080` directly to the entire internet.

For initial testing, you may temporarily use:

```text
http://<EC2-PUBLIC-IP>:8080
```

But GitHub must be able to reach it.

---

# 4. Install required Jenkins plugins

Open:

```text
Jenkins Dashboard
→ Manage Jenkins
→ Plugins
→ Available plugins
```

Install:

```text
Git
GitHub
Pipeline
Pipeline: Stage View
Credentials Binding
Docker Pipeline
```

Restart Jenkins after installing the plugins.

The Jenkins GitHub plugin integrates Jenkins jobs with GitHub repositories and can trigger jobs from GitHub webhook events. ([Jenkins Plugins][1])

---

# 5. Install Docker on the Jenkins EC2 instance

First identify the operating system:

```bash
cat /etc/os-release
```

## Amazon Linux 2023

```bash
sudo dnf update -y
sudo dnf install -y docker

sudo systemctl enable docker
sudo systemctl start docker
```

## Ubuntu

```bash
sudo apt-get update

sudo apt-get install -y \
  ca-certificates \
  curl \
  gnupg \
  docker.io

sudo systemctl enable docker
sudo systemctl start docker
```

Verify:

```bash
sudo docker version
sudo docker run --rm hello-world
```

---

# 6. Allow Jenkins to execute Docker commands

Jenkins normally runs as the Linux user:

```text
jenkins
```

Add the Jenkins user to the Docker group:

```bash
sudo usermod -aG docker jenkins
```

Restart both services:

```bash
sudo systemctl restart docker
sudo systemctl restart jenkins
```

Verify as the Jenkins user:

```bash
sudo -u jenkins -H docker version
```

Test Docker execution:

```bash
sudo -u jenkins -H docker run --rm hello-world
```

If you receive:

```text
permission denied while trying to connect to Docker daemon
```

Restart the EC2 instance:

```bash
sudo reboot
```

After reconnecting:

```bash
sudo -u jenkins -H docker version
```

---

# 7. Install AWS CLI on Jenkins EC2

Check whether AWS CLI already exists:

```bash
aws --version
```

For Linux x86_64:

```bash
cd /tmp

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" \
  -o "awscliv2.zip"

sudo dnf install -y unzip 2>/dev/null || \
sudo apt-get install -y unzip

unzip awscliv2.zip

sudo ./aws/install
```

Verify:

```bash
aws --version
```

Also verify it for Jenkins:

```bash
sudo -u jenkins -H aws --version
```

---

# 8. Install kubectl

The `kubectl` version should be within one minor version of the Kubernetes cluster version. ([Kubernetes][2])

For an EKS cluster, first check the cluster version:

```bash
aws eks describe-cluster \
  --name dev-eks-cluster \
  --region ap-south-1 \
  --query 'cluster.version' \
  --output text
```

Suppose the output is:

```text
1.34
```

Install a compatible kubectl version:

```bash
cd /tmp

curl -LO "https://dl.k8s.io/release/v1.34.0/bin/linux/amd64/kubectl"

chmod +x kubectl

sudo mv kubectl /usr/local/bin/kubectl
```

Verify:

```bash
kubectl version --client
sudo -u jenkins -H kubectl version --client
```

---

# 9. Create an ECR repository

Check whether the repository exists:

```bash
aws ecr describe-repositories \
  --repository-names demo-app \
  --region ap-south-1
```

Create it when it does not exist:

```bash
aws ecr create-repository \
  --repository-name demo-app \
  --region ap-south-1 \
  --image-scanning-configuration scanOnPush=true \
  --image-tag-mutability IMMUTABLE
```

Repository URL:

```text
123456789012.dkr.ecr.ap-south-1.amazonaws.com/demo-app
```

Get your actual AWS account ID:

```bash
aws sts get-caller-identity \
  --query Account \
  --output text
```

---

# 10. Create an IAM role for Jenkins EC2

The recommended approach is to attach an IAM role to the Jenkins EC2 instance instead of storing permanent AWS access keys inside Jenkins.

## 10.1 Create an IAM role

Go to:

```text
AWS Console
→ IAM
→ Roles
→ Create role
```

Select:

```text
Trusted entity: AWS service
Use case: EC2
```

Role name:

```text
JenkinsDevCICDRole
```

Attach this role to Jenkins EC2:

```text
EC2 Console
→ Instances
→ Select Jenkins instance
→ Actions
→ Security
→ Modify IAM role
→ JenkinsDevCICDRole
```

---

# 11. Add ECR permission to Jenkins role

Create an inline policy named:

```text
JenkinsECRPushPolicy
```

Use this policy and replace the account ID and Region:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "GetECRAuthorizationToken",
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken"
      ],
      "Resource": "*"
    },
    {
      "Sid": "PushAndReadDemoAppImages",
      "Effect": "Allow",
      "Action": [
        "ecr:BatchCheckLayerAvailability",
        "ecr:CompleteLayerUpload",
        "ecr:GetDownloadUrlForLayer",
        "ecr:InitiateLayerUpload",
        "ecr:PutImage",
        "ecr:UploadLayerPart",
        "ecr:BatchGetImage",
        "ecr:DescribeImages"
      ],
      "Resource": "arn:aws:ecr:ap-south-1:123456789012:repository/demo-app"
    }
  ]
}
```

Test the Jenkins EC2 role:

```bash
sudo -u jenkins -H aws sts get-caller-identity
```

Expected output will contain the EC2 role:

```json
{
  "Account": "123456789012",
  "Arn": "arn:aws:sts::123456789012:assumed-role/JenkinsDevCICDRole/..."
}
```

---

# 12. Give Jenkins access to EKS

The Jenkins EC2 IAM role needs permission to read the EKS cluster details.

Add this inline policy:

```text
JenkinsEKSDescribePolicy
```

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DescribeDevEKSCluster",
      "Effect": "Allow",
      "Action": [
        "eks:DescribeCluster"
      ],
      "Resource": "arn:aws:eks:ap-south-1:123456789012:cluster/dev-eks-cluster"
    }
  ]
}
```

This IAM permission allows Jenkins to discover the cluster endpoint. It does not, by itself, give Kubernetes authorization.

---

# 13. Create EKS access for Jenkins role

Run these commands using an AWS identity that already has EKS administrative access.

Set variables:

```bash
export AWS_REGION="ap-south-1"
export AWS_ACCOUNT_ID="123456789012"
export EKS_CLUSTER_NAME="dev-eks-cluster"
export JENKINS_ROLE_ARN="arn:aws:iam::123456789012:role/JenkinsDevCICDRole"
```

Create an EKS access entry:

```bash
aws eks create-access-entry \
  --cluster-name "${EKS_CLUSTER_NAME}" \
  --principal-arn "${JENKINS_ROLE_ARN}" \
  --type STANDARD \
  --region "${AWS_REGION}"
```

For a simple dev environment, associate the namespace-scoped edit policy:

```bash
aws eks associate-access-policy \
  --cluster-name "${EKS_CLUSTER_NAME}" \
  --principal-arn "${JENKINS_ROLE_ARN}" \
  --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy \
  --access-scope type=namespace,namespaces=dev \
  --region "${AWS_REGION}"
```

This limits Jenkins application deployment access to the `dev` namespace.

For the initial creation of namespace-level resources, an administrator may need to create the namespace first.

---

# 14. Generate kubeconfig for the Jenkins user

Run:

```bash
sudo mkdir -p /var/lib/jenkins/.kube

sudo chown -R jenkins:jenkins /var/lib/jenkins/.kube
```

Generate kubeconfig as Jenkins:

```bash
sudo -u jenkins -H aws eks update-kubeconfig \
  --name dev-eks-cluster \
  --region ap-south-1 \
  --kubeconfig /var/lib/jenkins/.kube/config
```

Protect the file:

```bash
sudo chmod 600 /var/lib/jenkins/.kube/config
sudo chown jenkins:jenkins /var/lib/jenkins/.kube/config
```

Test access:

```bash
sudo -u jenkins -H kubectl get namespaces
```

Create the namespace as an EKS administrator:

```bash
kubectl create namespace dev
```

If it already exists:

```text
Error from server (AlreadyExists)
```

That is fine.

Test Jenkins access:

```bash
sudo -u jenkins -H kubectl auth can-i get deployments -n dev
sudo -u jenkins -H kubectl auth can-i update deployments -n dev
sudo -u jenkins -H kubectl auth can-i create deployments -n dev
```

Expected:

```text
yes
yes
yes
```

---

# 15. Verify EKS network connectivity

Run from Jenkins EC2:

```bash
sudo -u jenkins -H kubectl cluster-info
```

If the command times out, check:

* EKS endpoint public/private configuration
* Jenkins EC2 VPC and subnets
* Route tables
* Security groups
* Network ACLs
* DNS resolution
* Proxy configuration

For a private EKS endpoint, Jenkins EC2 must have private network connectivity to the EKS control plane.

---

# 16. Repository structure

Your GitHub repository should look like:

```text
demo-app/
├── Jenkinsfile
├── Dockerfile
├── .dockerignore
├── package.json
├── server.js
└── k8s/
    └── dev/
        ├── namespace.yaml
        ├── deployment.yaml
        └── service.yaml
```

The sample application below uses Node.js because it is small and easy to test. The Jenkins and Kubernetes flow remains the same for Java, Python, React or another application.

---

# 17. Create a sample application

## `server.js`

```javascript
const http = require("http");

const port = process.env.PORT || 3000;
const environment = process.env.APP_ENV || "dev";
const buildNumber = process.env.BUILD_NUMBER || "local";

const server = http.createServer((request, response) => {
  if (request.url === "/health") {
    response.writeHead(200, {
      "Content-Type": "application/json"
    });

    response.end(
      JSON.stringify({
        status: "UP",
        environment,
        buildNumber
      })
    );

    return;
  }

  response.writeHead(200, {
    "Content-Type": "application/json"
  });

  response.end(
    JSON.stringify({
      message: "Application deployed successfully",
      environment,
      buildNumber
    })
  );
});

server.listen(port, "0.0.0.0", () => {
  console.log(`Server listening on port ${port}`);
});
```

## `package.json`

```json
{
  "name": "demo-app",
  "version": "1.0.0",
  "description": "Jenkins ECR EKS CI/CD demo application",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "test": "node --check server.js"
  },
  "engines": {
    "node": ">=20"
  }
}
```

---

# 18. Create the Dockerfile

## `Dockerfile`

```dockerfile
FROM node:20-alpine

WORKDIR /app

COPY package*.json ./

RUN npm install --omit=dev

COPY server.js ./

ARG BUILD_NUMBER=local

ENV PORT=3000
ENV APP_ENV=dev
ENV BUILD_NUMBER=${BUILD_NUMBER}

EXPOSE 3000

USER node

CMD ["node", "server.js"]
```

For Jenkins build number `42`, the build command will be:

```bash
docker build \
  --build-arg BUILD_NUMBER=42 \
  -t demo-app:dev-42 \
  .
```

---

# 19. Create `.dockerignore`

## `.dockerignore`

```text
.git
.gitignore
Jenkinsfile
README.md
node_modules
npm-debug.log
k8s
.env
.env.*
coverage
```

---

# 20. Create Kubernetes namespace manifest

## `k8s/dev/namespace.yaml`

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: dev
  labels:
    environment: dev
```

An EKS administrator can apply this once:

```bash
kubectl apply -f k8s/dev/namespace.yaml
```

---

# 21. Create Kubernetes Deployment

## `k8s/dev/deployment.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo-app
  namespace: dev
  labels:
    app: demo-app
    environment: dev
spec:
  replicas: 2

  revisionHistoryLimit: 5

  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 0
      maxSurge: 1

  selector:
    matchLabels:
      app: demo-app

  template:
    metadata:
      labels:
        app: demo-app
        environment: dev
    spec:
      containers:
        - name: demo-app

          # Jenkins replaces this value during deployment.
          image: 123456789012.dkr.ecr.ap-south-1.amazonaws.com/demo-app:dev-initial

          imagePullPolicy: IfNotPresent

          ports:
            - name: http
              containerPort: 3000
              protocol: TCP

          env:
            - name: APP_ENV
              value: dev

            - name: PORT
              value: "3000"

          readinessProbe:
            httpGet:
              path: /health
              port: http
            initialDelaySeconds: 5
            periodSeconds: 5
            timeoutSeconds: 2
            failureThreshold: 6

          livenessProbe:
            httpGet:
              path: /health
              port: http
            initialDelaySeconds: 15
            periodSeconds: 10
            timeoutSeconds: 2
            failureThreshold: 3

          resources:
            requests:
              cpu: 100m
              memory: 128Mi
            limits:
              cpu: 500m
              memory: 256Mi

      terminationGracePeriodSeconds: 30
```

Replace:

```text
123456789012
```

with your AWS account ID.

---

# 22. Create Kubernetes Service

## `k8s/dev/service.yaml`

```yaml
apiVersion: v1
kind: Service
metadata:
  name: demo-app
  namespace: dev
  labels:
    app: demo-app
    environment: dev
spec:
  type: ClusterIP

  selector:
    app: demo-app

  ports:
    - name: http
      port: 80
      targetPort: http
      protocol: TCP
```

This creates an internal Kubernetes service.

To expose the application externally for a quick dev test, change:

```yaml
type: ClusterIP
```

to:

```yaml
type: LoadBalancer
```

For a more realistic EKS environment, use an Ingress with the AWS Load Balancer Controller.

---

# 23. Create the Jenkinsfile

Create `Jenkinsfile` in the repository root:

```groovy
pipeline {
    agent any

    options {
        // Do not allow two dev deployments from this job at the same time.
        disableConcurrentBuilds()

        // Add timestamps to Jenkins logs.
        timestamps()

        // Keep only the latest 20 Jenkins builds.
        buildDiscarder(logRotator(
            numToKeepStr: '20',
            artifactNumToKeepStr: '10'
        ))

        // Stop a stuck pipeline after 30 minutes.
        timeout(time: 30, unit: 'MINUTES')
    }

    environment {
        AWS_ACCOUNT_ID = '123456789012'
        AWS_REGION = 'ap-south-1'

        APP_NAME = 'demo-app'
        ECR_REPOSITORY = 'demo-app'

        EKS_CLUSTER_NAME = 'dev-eks-cluster'

        K8S_NAMESPACE = 'dev'
        K8S_DEPLOYMENT = 'demo-app'
        K8S_CONTAINER = 'demo-app'

        ECR_REGISTRY = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        ECR_IMAGE = "${ECR_REGISTRY}/${ECR_REPOSITORY}"

        KUBECONFIG = '/var/lib/jenkins/.kube/config'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm

                script {
                    env.GIT_COMMIT_SHORT = sh(
                        script: 'git rev-parse --short=7 HEAD',
                        returnStdout: true
                    ).trim()

                    /*
                     * Example:
                     * BUILD_NUMBER = 42
                     * IMAGE_TAG = dev-42
                     * FULL_IMAGE_NAME =
                     * 123456789012.dkr.ecr.ap-south-1.amazonaws.com/demo-app:dev-42
                     */
                    env.IMAGE_TAG = "dev-${env.BUILD_NUMBER}"
                    env.FULL_IMAGE_NAME = "${env.ECR_IMAGE}:${env.IMAGE_TAG}"
                }

                sh '''
                    echo "=========================================="
                    echo "Git commit:       ${GIT_COMMIT}"
                    echo "Short commit:     ${GIT_COMMIT_SHORT}"
                    echo "Build number:     ${BUILD_NUMBER}"
                    echo "Image tag:        ${IMAGE_TAG}"
                    echo "Full image:       ${FULL_IMAGE_NAME}"
                    echo "Target namespace: ${K8S_NAMESPACE}"
                    echo "=========================================="
                '''
            }
        }

        stage('Validate Tools') {
            steps {
                sh '''
                    set -eux

                    git --version
                    docker --version
                    aws --version
                    kubectl version --client

                    aws sts get-caller-identity

                    docker info >/dev/null

                    kubectl cluster-info
                    kubectl auth can-i get deployments \
                      --namespace "${K8S_NAMESPACE}"
                    kubectl auth can-i update deployments \
                      --namespace "${K8S_NAMESPACE}"
                '''
            }
        }

        stage('Install Dependencies') {
            steps {
                sh '''
                    set -eux

                    docker run --rm \
                      -v "${WORKSPACE}:/app" \
                      -w /app \
                      node:20-alpine \
                      npm install
                '''
            }
        }

        stage('Test') {
            steps {
                sh '''
                    set -eux

                    docker run --rm \
                      -v "${WORKSPACE}:/app" \
                      -w /app \
                      node:20-alpine \
                      npm test
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                    set -eux

                    docker build \
                      --pull \
                      --build-arg BUILD_NUMBER="${BUILD_NUMBER}" \
                      --label "org.opencontainers.image.revision=${GIT_COMMIT}" \
                      --label "org.opencontainers.image.version=${IMAGE_TAG}" \
                      --label "jenkins.build.number=${BUILD_NUMBER}" \
                      --label "jenkins.build.url=${BUILD_URL}" \
                      --tag "${FULL_IMAGE_NAME}" \
                      .
                '''
            }
        }

        stage('Inspect Docker Image') {
            steps {
                sh '''
                    set -eux

                    docker image inspect "${FULL_IMAGE_NAME}"

                    docker image ls "${ECR_IMAGE}"
                '''
            }
        }

        stage('Login to ECR') {
            steps {
                sh '''
                    set -eux

                    aws ecr get-login-password \
                      --region "${AWS_REGION}" \
                    | docker login \
                      --username AWS \
                      --password-stdin "${ECR_REGISTRY}"
                '''
            }
        }

        stage('Push Image to ECR') {
            steps {
                sh '''
                    set -eux

                    docker push "${FULL_IMAGE_NAME}"

                    aws ecr describe-images \
                      --repository-name "${ECR_REPOSITORY}" \
                      --image-ids imageTag="${IMAGE_TAG}" \
                      --region "${AWS_REGION}"
                '''
            }
        }

        stage('Configure EKS Access') {
            steps {
                sh '''
                    set -eux

                    aws eks update-kubeconfig \
                      --name "${EKS_CLUSTER_NAME}" \
                      --region "${AWS_REGION}" \
                      --kubeconfig "${KUBECONFIG}"

                    kubectl config current-context
                    kubectl get namespace "${K8S_NAMESPACE}"
                '''
            }
        }

        stage('Apply Kubernetes Resources') {
            steps {
                sh '''
                    set -eux

                    kubectl apply \
                      -f k8s/dev/service.yaml

                    /*
                     * Apply the Deployment only when it does not already exist.
                     * This prevents deployment.yaml's placeholder image from
                     * temporarily replacing an existing working image.
                     */
                    if ! kubectl get deployment "${K8S_DEPLOYMENT}" \
                      --namespace "${K8S_NAMESPACE}" >/dev/null 2>&1; then

                      echo "Deployment does not exist. Creating it."

                      kubectl apply \
                        -f k8s/dev/deployment.yaml
                    else
                      echo "Deployment already exists."
                    fi
                '''
            }
        }

        stage('Deploy Image to Kubernetes') {
            steps {
                sh '''
                    set -eux

                    kubectl set image \
                      deployment/"${K8S_DEPLOYMENT}" \
                      "${K8S_CONTAINER}"="${FULL_IMAGE_NAME}" \
                      --namespace "${K8S_NAMESPACE}"

                    kubectl annotate \
                      deployment/"${K8S_DEPLOYMENT}" \
                      --namespace "${K8S_NAMESPACE}" \
                      kubernetes.io/change-cause="Jenkins build ${BUILD_NUMBER}, image ${IMAGE_TAG}, commit ${GIT_COMMIT_SHORT}" \
                      --overwrite
                '''
            }
        }

        stage('Wait for Rollout') {
            steps {
                sh '''
                    set -eux

                    kubectl rollout status \
                      deployment/"${K8S_DEPLOYMENT}" \
                      --namespace "${K8S_NAMESPACE}" \
                      --timeout=300s
                '''
            }
        }

        stage('Verify Deployment') {
            steps {
                sh '''
                    set -eux

                    DEPLOYED_IMAGE="$(
                      kubectl get deployment "${K8S_DEPLOYMENT}" \
                        --namespace "${K8S_NAMESPACE}" \
                        --output jsonpath='{.spec.template.spec.containers[?(@.name=="'"${K8S_CONTAINER}"'")].image}'
                    )"

                    echo "Expected image: ${FULL_IMAGE_NAME}"
                    echo "Deployed image: ${DEPLOYED_IMAGE}"

                    if [ "${DEPLOYED_IMAGE}" != "${FULL_IMAGE_NAME}" ]; then
                      echo "Deployment verification failed."
                      exit 1
                    fi

                    kubectl get deployment "${K8S_DEPLOYMENT}" \
                      --namespace "${K8S_NAMESPACE}" \
                      --output wide

                    kubectl get pods \
                      --namespace "${K8S_NAMESPACE}" \
                      --selector "app=${APP_NAME}" \
                      --output wide

                    kubectl get service "${APP_NAME}" \
                      --namespace "${K8S_NAMESPACE}"
                '''
            }
        }
    }

    post {
        success {
            echo """
            Deployment completed successfully.

            Environment:    dev
            Build number:   ${env.BUILD_NUMBER}
            Image tag:      ${env.IMAGE_TAG}
            Docker image:   ${env.FULL_IMAGE_NAME}
            Namespace:      ${env.K8S_NAMESPACE}
            Deployment:     ${env.K8S_DEPLOYMENT}
            Git commit:     ${env.GIT_COMMIT_SHORT}
            """
        }

        failure {
            echo """
            Pipeline failed.

            Build number: ${env.BUILD_NUMBER}
            Image tag:    ${env.IMAGE_TAG}
            Check the failed Jenkins stage and Kubernetes events.
            """

            sh '''
                echo "Current deployment:"
                kubectl get deployment "${K8S_DEPLOYMENT}" \
                  --namespace "${K8S_NAMESPACE}" \
                  --output wide || true

                echo "Current pods:"
                kubectl get pods \
                  --namespace "${K8S_NAMESPACE}" \
                  --selector "app=${APP_NAME}" \
                  --output wide || true

                echo "Recent Kubernetes events:"
                kubectl get events \
                  --namespace "${K8S_NAMESPACE}" \
                  --sort-by='.lastTimestamp' \
                  | tail -30 || true
            '''
        }

        always {
            sh '''
                docker logout "${ECR_REGISTRY}" || true

                if [ -n "${FULL_IMAGE_NAME:-}" ]; then
                  docker image rm "${FULL_IMAGE_NAME}" || true
                fi

                docker image prune --force || true
            '''

            deleteDir()
        }
    }
}
```

## Important correction in the Jenkinsfile

Shell scripts cannot contain Groovy-style comments such as:

```text
/*
 ...
*/
```

Therefore, in the `Apply Kubernetes Resources` stage, use this exact version:

```groovy
stage('Apply Kubernetes Resources') {
    steps {
        sh '''
            set -eux

            kubectl apply \
              -f k8s/dev/service.yaml

            # Create the Deployment only when it does not already exist.
            if ! kubectl get deployment "${K8S_DEPLOYMENT}" \
              --namespace "${K8S_NAMESPACE}" >/dev/null 2>&1; then

              echo "Deployment does not exist. Creating it."

              kubectl apply \
                -f k8s/dev/deployment.yaml
            else
              echo "Deployment already exists."
            fi
        '''
    }
}
```

Use the corrected stage above in your final file.

Amazon ECR authentication uses `aws ecr get-login-password`, piped into `docker login` with `AWS` as the username. ([AWS Documentation][3])

The deployment stage uses `kubectl set image` to update the Deployment’s pod template, followed by `kubectl rollout status` to wait for the rolling deployment to complete. ([Kubernetes][4])

---

# 24. Commit the files to GitHub

```bash
git checkout -b dev
```

Add files:

```bash
git add \
  Jenkinsfile \
  Dockerfile \
  .dockerignore \
  package.json \
  server.js \
  k8s/dev/namespace.yaml \
  k8s/dev/deployment.yaml \
  k8s/dev/service.yaml
```

Commit:

```bash
git commit -m "Add Jenkins ECR EKS dev CI/CD pipeline"
```

Push:

```bash
git push -u origin dev
```

---

# 25. Configure GitHub credentials in Jenkins

For a public GitHub repository, credentials may not be required.

For a private repository, create a GitHub Personal Access Token or use a GitHub App.

Open:

```text
Jenkins
→ Manage Jenkins
→ Credentials
→ System
→ Global credentials
→ Add Credentials
```

Use:

```text
Kind: Username with password
Username: your-github-username
Password: your GitHub token
ID: github-credentials
Description: GitHub repository credentials
```

Do not put the GitHub token inside the Jenkinsfile.

---

# 26. Create the Jenkins Pipeline job

Open:

```text
Jenkins Dashboard
→ New Item
```

Enter:

```text
demo-app-dev
```

Select:

```text
Pipeline
```

Click:

```text
OK
```

---

# 27. Configure the Jenkins job

## General

Enable:

```text
GitHub project
```

Project URL:

```text
https://github.com/YOUR_USERNAME/YOUR_REPOSITORY/
```

## Build Triggers

Enable:

```text
GitHub hook trigger for GITScm polling
```

Do not enable regular SCM polling unless you deliberately need a backup polling mechanism.

## Pipeline

Select:

```text
Definition: Pipeline script from SCM
SCM: Git
```

Repository URL:

```text
https://github.com/YOUR_USERNAME/YOUR_REPOSITORY.git
```

Credentials:

```text
github-credentials
```

Branch specifier:

```text
*/dev
```

Script path:

```text
Jenkinsfile
```

Enable:

```text
Lightweight checkout
```

Click:

```text
Save
```

---

# 28. Make Jenkins reachable from GitHub

From your local machine, test:

```bash
curl -I https://jenkins.example.com/login
```

Or, temporarily:

```bash
curl -I http://<EC2-PUBLIC-IP>:8080/login
```

GitHub must be able to reach:

```text
https://jenkins.example.com/github-webhook/
```

Do not use:

```text
http://localhost:8080/github-webhook/
```

GitHub cannot reach your EC2 instance using `localhost`.

---

# 29. Configure the GitHub webhook

Open your GitHub repository:

```text
Repository
→ Settings
→ Webhooks
→ Add webhook
```

Configure:

```text
Payload URL:
https://jenkins.example.com/github-webhook/

Content type:
application/json

SSL verification:
Enable SSL verification

Which events?
Just the push event

Active:
Checked
```

Click:

```text
Add webhook
```

For initial testing using an EC2 public address:

```text
http://<EC2-PUBLIC-IP>:8080/github-webhook/
```

HTTPS with a valid certificate is strongly recommended.

---

# 30. Test the webhook

Make a small source code change:

```javascript
message: "Application deployed through Jenkins CI/CD"
```

Commit and push:

```bash
git add server.js

git commit -m "Test automatic Jenkins deployment"

git push origin dev
```

Expected flow:

```text
1. GitHub sends a push webhook.
2. Jenkins receives /github-webhook/.
3. Jenkins starts demo-app-dev.
4. BUILD_NUMBER is assigned, for example 42.
5. Docker image demo-app:dev-42 is built.
6. Image is pushed to ECR.
7. Kubernetes Deployment is updated.
8. Kubernetes performs a rolling deployment.
9. Jenkins waits for rollout completion.
10. Jenkins verifies the deployed image.
```

---

# 31. Sample build-number values

Jenkins automatically provides the `BUILD_NUMBER` variable.

For example:

```text
First run:       BUILD_NUMBER=1
Second run:      BUILD_NUMBER=2
Forty-second run: BUILD_NUMBER=42
```

For build `42`:

```text
IMAGE_TAG=dev-42
```

Full image:

```text
123456789012.dkr.ecr.ap-south-1.amazonaws.com/demo-app:dev-42
```

Docker build:

```bash
docker build \
  --build-arg BUILD_NUMBER=42 \
  -t 123456789012.dkr.ecr.ap-south-1.amazonaws.com/demo-app:dev-42 \
  .
```

Docker push:

```bash
docker push \
  123456789012.dkr.ecr.ap-south-1.amazonaws.com/demo-app:dev-42
```

Kubernetes deployment:

```bash
kubectl set image \
  deployment/demo-app \
  demo-app=123456789012.dkr.ecr.ap-south-1.amazonaws.com/demo-app:dev-42 \
  --namespace dev
```

Rollout verification:

```bash
kubectl rollout status \
  deployment/demo-app \
  --namespace dev \
  --timeout=300s
```

---

# 32. Manually test every pipeline command

Before depending on Jenkins, verify the entire process as the Jenkins Linux user.

## Verify AWS identity

```bash
sudo -u jenkins -H aws sts get-caller-identity
```

## Verify ECR login

```bash
sudo -u jenkins -H bash -c '
AWS_REGION="ap-south-1"
AWS_ACCOUNT_ID="123456789012"
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

aws ecr get-login-password \
  --region "${AWS_REGION}" \
| docker login \
  --username AWS \
  --password-stdin "${ECR_REGISTRY}"
'
```

## Verify Kubernetes access

```bash
sudo -u jenkins -H kubectl get deployment -n dev
```

## Verify update permission

```bash
sudo -u jenkins -H kubectl auth can-i update deployment -n dev
```

Expected:

```text
yes
```

---

# 33. Check the deployed application

View resources:

```bash
kubectl get all -n dev
```

View pods:

```bash
kubectl get pods \
  -n dev \
  -l app=demo-app \
  -o wide
```

View image:

```bash
kubectl get deployment demo-app \
  -n dev \
  -o jsonpath='{.spec.template.spec.containers[0].image}'
```

Expected for build 42:

```text
123456789012.dkr.ecr.ap-south-1.amazonaws.com/demo-app:dev-42
```

Port-forward for testing:

```bash
kubectl port-forward \
  -n dev \
  service/demo-app \
  8081:80
```

Open:

```text
http://localhost:8081
```

Health endpoint:

```bash
curl http://localhost:8081/health
```

Expected response:

```json
{
  "status": "UP",
  "environment": "dev",
  "buildNumber": "42"
}
```

---

# 34. Verify the image in ECR

```bash
aws ecr describe-images \
  --repository-name demo-app \
  --region ap-south-1 \
  --query 'imageDetails[*].[imageTags[0],imagePushedAt,imageDigest]' \
  --output table
```

Expected:

```text
dev-42
```

---

# 35. Verify rollout history

```bash
kubectl rollout history \
  deployment/demo-app \
  -n dev
```

You should see change-cause information similar to:

```text
Jenkins build 42, image dev-42, commit a1b2c3d
```

Kubernetes supports viewing prior rollout revisions with `kubectl rollout history`. ([Kubernetes][5])

---

# 36. Roll back a failed deployment

Check history:

```bash
kubectl rollout history \
  deployment/demo-app \
  -n dev
```

Rollback to the previous revision:

```bash
kubectl rollout undo \
  deployment/demo-app \
  -n dev
```

Wait for rollback:

```bash
kubectl rollout status \
  deployment/demo-app \
  -n dev \
  --timeout=300s
```

Rollback to a specific revision:

```bash
kubectl rollout undo \
  deployment/demo-app \
  -n dev \
  --to-revision=3
```

---

# 37. Common webhook problems

## GitHub says webhook delivery failed

Check whether the Jenkins URL is reachable:

```bash
curl -I https://jenkins.example.com/github-webhook/
```

A `404`, `405`, or similar HTTP response may still prove that the endpoint is reachable. A timeout means a network, DNS, firewall or security-group issue.

Check:

```text
EC2 security group
Load balancer listener
DNS record
TLS certificate
Nginx configuration
Jenkins base URL
GitHub webhook delivery response
```

In GitHub:

```text
Repository
→ Settings
→ Webhooks
→ Select webhook
→ Recent Deliveries
```

Click:

```text
Redeliver
```

---

# 38. Jenkins receives webhook but pipeline does not run

Verify the Jenkins job has:

```text
GitHub hook trigger for GITScm polling
```

Verify the branch:

```text
*/dev
```

Verify the pushed branch really is:

```text
dev
```

Verify the repository URL is correct.

Check:

```text
Jenkins
→ Manage Jenkins
→ System Log
```

You can also inspect the GitHub plugin logs.

---

# 39. Docker permission denied

Error:

```text
permission denied while trying to connect to the Docker daemon socket
```

Fix:

```bash
sudo usermod -aG docker jenkins

sudo systemctl restart docker
sudo systemctl restart jenkins
```

Verify:

```bash
sudo -u jenkins -H docker ps
```

---

# 40. ECR push denied

Error examples:

```text
no basic auth credentials
```

or:

```text
User is not authorized to perform ecr:PutImage
```

Check AWS identity:

```bash
sudo -u jenkins -H aws sts get-caller-identity
```

Login manually:

```bash
sudo -u jenkins -H bash -c '
aws ecr get-login-password \
  --region ap-south-1 \
| docker login \
  --username AWS \
  --password-stdin \
  123456789012.dkr.ecr.ap-south-1.amazonaws.com
'
```

Verify IAM role permissions and ECR repository ARN.

---

# 41. Kubernetes authentication failure

Error:

```text
You must be logged in to the server
```

Regenerate kubeconfig:

```bash
sudo -u jenkins -H aws eks update-kubeconfig \
  --name dev-eks-cluster \
  --region ap-south-1 \
  --kubeconfig /var/lib/jenkins/.kube/config
```

Then test:

```bash
sudo -u jenkins -H kubectl get namespace dev
```

---

# 42. Kubernetes authorization failure

Error:

```text
deployments.apps is forbidden
```

Authentication is working, but the IAM role does not have sufficient Kubernetes permissions.

Check:

```bash
sudo -u jenkins -H kubectl auth can-i update deployments -n dev
```

Inspect the EKS access entry:

```bash
aws eks describe-access-entry \
  --cluster-name dev-eks-cluster \
  --principal-arn arn:aws:iam::123456789012:role/JenkinsDevCICDRole \
  --region ap-south-1
```

List associated policies:

```bash
aws eks list-associated-access-policies \
  --cluster-name dev-eks-cluster \
  --principal-arn arn:aws:iam::123456789012:role/JenkinsDevCICDRole \
  --region ap-south-1
```

---

# 43. Kubernetes ImagePullBackOff

Check pod events:

```bash
kubectl describe pod \
  -n dev \
  <POD_NAME>
```

Common causes:

* Wrong ECR URL
* Wrong AWS account ID
* Wrong Region
* ECR repository does not exist
* EKS worker-node role cannot pull from ECR
* Image tag does not exist
* Private networking does not allow ECR access

Confirm the image exists:

```bash
aws ecr describe-images \
  --repository-name demo-app \
  --image-ids imageTag=dev-42 \
  --region ap-south-1
```

---

# 44. Rollout timeout

Check:

```bash
kubectl get pods -n dev -l app=demo-app
```

Describe the unhealthy pod:

```bash
kubectl describe pod -n dev <POD_NAME>
```

View logs:

```bash
kubectl logs -n dev <POD_NAME>
```

View previous container logs after a restart:

```bash
kubectl logs \
  -n dev \
  <POD_NAME> \
  --previous
```

View recent events:

```bash
kubectl get events \
  -n dev \
  --sort-by='.lastTimestamp'
```

---

# 45. Recommended Jenkins URL configuration

Open:

```text
Manage Jenkins
→ System
→ Jenkins Location
```

Set:

```text
Jenkins URL:
https://jenkins.example.com/
```

Do not set:

```text
http://localhost:8080/
```

---

# 46. Recommended ECR lifecycle policy

Builds create many images. Add an ECR lifecycle policy to retain only recent dev images.

Create `ecr-lifecycle-policy.json`:

```json
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Keep the latest 30 dev images",
      "selection": {
        "tagStatus": "tagged",
        "tagPrefixList": [
          "dev-"
        ],
        "countType": "imageCountMoreThan",
        "countNumber": 30
      },
      "action": {
        "type": "expire"
      }
    },
    {
      "rulePriority": 2,
      "description": "Remove untagged images after seven days",
      "selection": {
        "tagStatus": "untagged",
        "countType": "sinceImagePushed",
        "countUnit": "days",
        "countNumber": 7
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}
```

Apply:

```bash
aws ecr put-lifecycle-policy \
  --repository-name demo-app \
  --lifecycle-policy-text file://ecr-lifecycle-policy.json \
  --region ap-south-1
```

---

# 47. Complete first-run checklist

Before your first push, verify every item:

```text
[ ] Jenkins service is running
[ ] Jenkins URL is reachable from GitHub
[ ] GitHub plugin is installed
[ ] Git plugin is installed
[ ] Pipeline plugin is installed
[ ] Docker is installed
[ ] Jenkins user can execute Docker
[ ] AWS CLI is installed
[ ] kubectl is installed
[ ] EC2 IAM role is attached
[ ] IAM role can authenticate to ECR
[ ] IAM role can push to the demo-app ECR repository
[ ] IAM role can describe the EKS cluster
[ ] EKS access entry exists for Jenkins IAM role
[ ] Jenkins has permission in namespace dev
[ ] Jenkins kubeconfig exists
[ ] Jenkins can reach the Kubernetes API
[ ] dev namespace exists
[ ] Dockerfile is committed
[ ] Kubernetes manifests are committed
[ ] Jenkinsfile is committed
[ ] Jenkins job points to the dev branch
[ ] GitHub webhook points to /github-webhook/
[ ] GitHub webhook is active
[ ] Push event is selected
```

Once this is configured, every push to the `dev` branch will produce an image such as `dev-42`, push it to ECR and deploy it to the `dev` namespace.

[1]: https://plugins.jenkins.io/github/?utm_source=chatgpt.com "GitHub | Jenkins plugin"
[2]: https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/?utm_source=chatgpt.com "Install and Set Up kubectl on Linux"
[3]: https://docs.aws.amazon.com/AmazonECR/latest/userguide/docker-push-ecr-image.html?utm_source=chatgpt.com "push a Docker image to an Amazon ECR repository"
[4]: https://kubernetes.io/docs/reference/kubectl/generated/kubectl_set/kubectl_set_image/?utm_source=chatgpt.com "kubectl set image"
[5]: https://kubernetes.io/docs/reference/kubectl/generated/kubectl_rollout/kubectl_rollout_history/?utm_source=chatgpt.com "kubectl rollout history"
