You can do this setup, but one correction first:

For **Tomcat**, normally we build a **`.war` file**, not `.jar`.

```text id="lzje0e"
Tomcat external server → WAR file
Spring Boot embedded Tomcat → JAR file
```

Since you said **frontend app on Tomcat**, the proper CI/CD flow is:

```text id="hlszd5"
Git/GitHub
   ↓
Jenkins auto trigger
   ↓
Maven build
   ↓
Generate WAR file
   ↓
Build Docker image with Tomcat
   ↓
Run application container
```

Cloud Shell is okay to create resources, but not ideal to run Jenkins permanently because Cloud Shell sessions are interactive and time-limited. Google Cloud Shell sessions can terminate after time limits, so for Jenkins you should create a **GCP VM** from Cloud Shell and install Jenkins/Docker there. ([Google Cloud Documentation][1])

---

# Final Architecture

```text id="dvarn5"
Developer
   |
   | git push
   ↓
GitHub Repo
   |
   | Webhook
   ↓
Jenkins running on GCP VM
   |
   | Maven build
   ↓
target/myapp.war
   |
   | Docker build
   ↓
Tomcat Docker Image
   |
   | Docker run
   ↓
Application available on port 8081
```

Jenkins is commonly used for CI/CD automation, and the Jenkins Docker image is officially supported for running Jenkins in containers. ([Jenkins][2])

---

# Step 1: Create GCP VM from Cloud Shell

Open **GCP Cloud Shell** and run:

```bash id="m0qtdv"
gcloud compute instances create jenkins-vm \
  --zone=asia-south1-a \
  --machine-type=e2-medium \
  --image-family=ubuntu-2204-lts \
  --image-project=ubuntu-os-cloud \
  --boot-disk-size=30GB \
  --tags=jenkins-server
```

Allow Jenkins and app ports:

```bash id="qlzdp6"
gcloud compute firewall-rules create allow-jenkins-8080 \
  --allow=tcp:8080 \
  --target-tags=jenkins-server \
  --source-ranges=0.0.0.0/0

gcloud compute firewall-rules create allow-app-8081 \
  --allow=tcp:8081 \
  --target-tags=jenkins-server \
  --source-ranges=0.0.0.0/0
```

SSH into VM:

```bash id="o57h4i"
gcloud compute ssh jenkins-vm --zone=asia-south1-a
```

---

# Step 2: Install Docker on VM

Inside the VM:

```bash id="em5gmi"
sudo apt update
sudo apt install -y docker.io git curl
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker $USER
```

Now logout and SSH again:

```bash id="z9ymud"
exit
```

Then reconnect:

```bash id="w2k4cd"
gcloud compute ssh jenkins-vm --zone=asia-south1-a
```

Check Docker:

```bash id="ccmh6t"
docker --version
docker ps
```

---

# Step 3: Run Jenkins using Docker

Run Jenkins container:

```bash id="c8suxu"
docker run -d \
  --name jenkins \
  --restart unless-stopped \
  -p 8080:8080 \
  -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  jenkins/jenkins:lts
```

The Jenkins official Docker docs use `jenkins/jenkins:lts` and persist Jenkins data using a volume. ([Jenkins][3])

Now get initial password:

```bash id="jlzng0"
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

Open Jenkins in browser:

```text id="pvb9lo"
http://VM_EXTERNAL_IP:8080
```

Get VM external IP:

```bash id="g8myzb"
curl ifconfig.me
```

Or from Cloud Shell:

```bash id="w4jo6z"
gcloud compute instances list
```

Install suggested plugins.

Also install these Jenkins plugins:

```text id="c3psox"
Git
GitHub
Pipeline
Docker Pipeline
```

The Jenkins GitHub plugin supports the “GitHub hook trigger for GITScm polling” trigger, which lets GitHub push events start Jenkins builds. ([Jenkins Plugins][4])

---

# Step 4: Create GitHub repo structure

Your repo can be:

```text id="8t4e03"
tomcat-frontend-demo/
│
├── pom.xml
├── Dockerfile
├── Jenkinsfile
└── src/
    └── main/
        └── webapp/
            ├── index.html
            └── WEB-INF/
                └── web.xml
```

---

# Step 5: Create `pom.xml`

This will generate a **WAR file** for Tomcat.

```xml id="bf96qs"
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
         https://maven.apache.org/xsd/maven-4.0.0.xsd">

    <modelVersion>4.0.0</modelVersion>

    <groupId>com.demo</groupId>
    <artifactId>tomcat-frontend-demo</artifactId>
    <version>1.0.0</version>
    <packaging>war</packaging>

    <build>
        <finalName>frontend-app</finalName>
    </build>

</project>
```

This will create:

```text id="r0dio8"
target/frontend-app.war
```

---

# Step 6: Create basic frontend file

Create:

```text id="qoxs2f"
src/main/webapp/index.html
```

Content:

```html id="eumcru"
<!DOCTYPE html>
<html>
<head>
    <title>Jenkins Tomcat Demo</title>
</head>
<body>
    <h1>Hello from Jenkins + GitHub + Docker + Tomcat</h1>
    <p>This frontend application was built automatically by Jenkins.</p>
</body>
</html>
```

---

# Step 7: Create `web.xml`

Create:

```text id="rp5653"
src/main/webapp/WEB-INF/web.xml
```

Content:

```xml id="n4y9zt"
<web-app xmlns="https://jakarta.ee/xml/ns/jakartaee"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="https://jakarta.ee/xml/ns/jakartaee
         https://jakarta.ee/xml/ns/jakartaee/web-app_6_0.xsd"
         version="6.0">

    <display-name>Tomcat Frontend Demo</display-name>

</web-app>
```

---

# Step 8: Create Dockerfile

Create:

```text id="hwnd0g"
Dockerfile
```

Content:

```dockerfile id="bzp78y"
FROM tomcat:10.1-jdk17-temurin

RUN rm -rf /usr/local/tomcat/webapps/*

COPY target/frontend-app.war /usr/local/tomcat/webapps/ROOT.war

EXPOSE 8080

CMD ["catalina.sh", "run"]
```

The `tomcat` Docker image is an official Docker image, and it is commonly used for containerizing applications that run on Apache Tomcat. ([Docker Hub][5])

---

# Step 9: Create Jenkinsfile

Create:

```text id="buy7gw"
Jenkinsfile
```

Content:

```groovy id="mknaqu"
pipeline {
    agent any

    environment {
        APP_NAME = 'tomcat-frontend-demo'
        IMAGE_NAME = 'tomcat-frontend-demo'
        CONTAINER_NAME = 'tomcat-frontend-container'
    }

    triggers {
        githubPush()
    }

    stages {
        stage('Checkout Code') {
            steps {
                echo 'Checking out latest code from GitHub...'
                checkout scm
            }
        }

        stage('Verify Files') {
            steps {
                echo 'Verifying project structure...'
                sh 'ls -la'
                sh 'ls -la src/main/webapp'
            }
        }

        stage('Build WAR') {
            steps {
                echo 'Building WAR file using Maven...'
                sh 'mvn clean package'
            }
        }

        stage('Verify WAR') {
            steps {
                echo 'Checking generated WAR file...'
                sh 'ls -la target'
            }
        }

        stage('Build Docker Image') {
            steps {
                echo 'Building Docker image...'
                sh 'docker build -t ${IMAGE_NAME}:latest .'
            }
        }

        stage('Stop Old Container') {
            steps {
                echo 'Stopping old container if running...'
                sh '''
                    docker stop ${CONTAINER_NAME} || true
                    docker rm ${CONTAINER_NAME} || true
                '''
            }
        }

        stage('Run New Container') {
            steps {
                echo 'Starting new Tomcat container...'
                sh '''
                    docker run -d \
                    --name ${CONTAINER_NAME} \
                    -p 8081:8080 \
                    ${IMAGE_NAME}:latest
                '''
            }
        }

        stage('Verify Deployment') {
            steps {
                echo 'Verifying deployed application...'
                sh 'sleep 10'
                sh 'curl -I http://localhost:8081'
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully. Application is deployed on Tomcat Docker container.'
        }

        failure {
            echo 'Pipeline failed. Please check console logs.'
        }

        always {
            echo 'Pipeline execution finished.'
        }
    }
}
```

---

# Step 10: Push code to GitHub

From your local machine or Cloud Shell:

```bash id="mxg591"
git init
git add .
git commit -m "Initial Tomcat frontend Jenkins Docker setup"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/tomcat-frontend-demo.git
git push -u origin main
```

---

# Step 11: Add GitHub credentials in Jenkins

In Jenkins:

```text id="qprrbi"
Manage Jenkins → Credentials → System → Global credentials → Add Credentials
```

Use:

```text id="fgdr7a"
Kind: Username with password
Username: your-github-username
Password: GitHub Personal Access Token
ID: github-token
Description: GitHub token for Jenkins
```

---

# Step 12: Create Jenkins pipeline job

In Jenkins:

```text id="24ka08"
New Item → Pipeline → Name: tomcat-frontend-pipeline → OK
```

In job config:

```text id="bnk8ao"
Definition: Pipeline script from SCM
SCM: Git
Repository URL: https://github.com/YOUR_USERNAME/tomcat-frontend-demo.git
Credentials: github-token
Branch: */main
Script Path: Jenkinsfile
```

Enable build trigger:

```text id="im9byv"
GitHub hook trigger for GITScm polling
```

Save.

---

# Step 13: Add GitHub webhook

In GitHub repo:

```text id="2k0znu"
Settings → Webhooks → Add webhook
```

Use:

```text id="9uebyf"
Payload URL:
http://VM_EXTERNAL_IP:8080/github-webhook/

Content type:
application/json

Events:
Just the push event

Active:
Checked
```

GitHub webhooks deliver events to an external web server when selected GitHub events happen, such as push events. ([GitHub Docs][6])

---

# Step 14: Test auto build

Update:

```text id="pm5e0g"
src/main/webapp/index.html
```

Change text:

```html id="g2wumt"
<h1>Version 2 deployed automatically by Jenkins</h1>
```

Push:

```bash id="kpf2of"
git add .
git commit -m "Update frontend page"
git push origin main
```

Expected result:

```text id="diu0no"
GitHub webhook triggers Jenkins
Jenkins pulls latest code
Maven creates target/frontend-app.war
Docker builds new Tomcat image
Old container stops
New container starts
Application updates on port 8081
```

Open:

```text id="h7o196"
http://VM_EXTERNAL_IP:8081
```

You should see the updated page.

---

# Important: Jenkins container needs Maven and Docker

The default Jenkins Docker image may not have Maven installed. So better create a custom Jenkins image.

On the VM, create a folder:

```bash id="hq65bp"
mkdir ~/jenkins-custom
cd ~/jenkins-custom
```

Create Dockerfile:

```dockerfile id="zbq29p"
FROM jenkins/jenkins:lts

USER root

RUN apt-get update && \
    apt-get install -y maven docker.io curl git && \
    apt-get clean

USER jenkins
```

Build it:

```bash id="phub9e"
docker build -t custom-jenkins:lts .
```

Stop old Jenkins:

```bash id="2yod8b"
docker stop jenkins
docker rm jenkins
```

Run custom Jenkins:

```bash id="4tocbr"
docker run -d \
  --name jenkins \
  --restart unless-stopped \
  -p 8080:8080 \
  -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  custom-jenkins:lts
```

Now Jenkins can run:

```bash id="b7u4cs"
mvn clean package
docker build
docker run
```

---

# For your explanation/demo

You can explain it like this:

```text id="be0d7l"
I created a CI/CD pipeline using Git, GitHub, Jenkins, Maven, Docker, and Tomcat.

Whenever a developer pushes code to GitHub, GitHub sends a webhook to Jenkins.
Jenkins checks out the latest code, builds the frontend application using Maven,
generates a WAR file, creates a Docker image using the Tomcat base image,
stops the previous running container, and starts a new container with the latest build.

This gives us automatic build and deployment whenever code changes.
```

---

# Simple version of the flow

```text id="nvnqtm"
Code change
   ↓
git push
   ↓
GitHub webhook
   ↓
Jenkins pipeline
   ↓
mvn clean package
   ↓
target/frontend-app.war
   ↓
docker build
   ↓
docker run Tomcat
   ↓
App deployed
```

This is the proper Git + GitHub + Jenkins + Docker + Tomcat setup.

[1]: https://docs.cloud.google.com/shell/docs/quotas-limits?utm_source=chatgpt.com "Quotas and limits | Cloud Shell"
[2]: https://www.jenkins.io/?utm_source=chatgpt.com "Jenkins"
[3]: https://www.jenkins.io/doc/book/installing/docker/?utm_source=chatgpt.com "Docker"
[4]: https://plugins.jenkins.io/github/?utm_source=chatgpt.com "GitHub | Jenkins plugin"
[5]: https://hub.docker.com/_/tomcat?utm_source=chatgpt.com "tomcat - Official Image"
[6]: https://docs.github.com/en/webhooks?utm_source=chatgpt.com "Webhooks documentation"
