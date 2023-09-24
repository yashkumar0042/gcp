# Lab Instructions: Google Cloud Run - Deploying and Managing Containers

## Objective

In this lab, you will learn how to deploy and manage containers using Google Cloud Run. You will explore various aspects of Cloud Run, including deploying a predefined Docker image, building a custom image with a Python application, and performing traffic splitting between different versions of your application.

## Prerequisites

1. A Google Cloud Platform (GCP) account with billing enabled.
2. Google Cloud Console access.

## Lab Steps

### Part 1: Deploying a Predefined Docker Image

In this part, you will deploy a predefined Docker image to Cloud Run.

#### GUI Instructions:

1. Open the [Google Cloud Console](https://console.cloud.google.com/).

2. Select your GCP project or create a new one.

3. In the left navigation pane, go to "Cloud Run."

4. Click "Create Service."

5. Choose a deployment platform (e.g., "Fully managed").

6. Click "Next."

7. Configure the service:
   - **Service Name**: Enter a name for your service.
   - **Deployment Platform**: Select "Fully managed."
   - **Region**: Choose a region.
   - **Authentication**: Leave it as "Allow unauthenticated invocations."
   - **Container Image**: Enter a predefined Docker image URL (e.g., `gcr.io/cloudrun/hello`).

8. Click "Next."

9. Review your configuration and click "Create" to deploy the service.

10. Once the deployment is complete, click the service URL to access your deployed application.

#### CLI Instructions:

1. Open Cloud Shell by clicking the Cloud Shell icon (![Cloud Shell Icon](https://cloud.google.com/shell/docs/images/activate-cloud-shell-icon.png)) in the Google Cloud Console toolbar.

2. Run the following command to deploy a predefined Docker image:

   ```bash
   gcloud run deploy <SERVICE_NAME> \
     --image gcr.io/cloudrun/hello \
     --platform managed \
     --region <REGION>
   ```

   Replace `<SERVICE_NAME>` with a name for your service, and `<REGION>` with your desired region.

3. Follow the prompts to allow unauthenticated invocations and confirm the deployment.

4. Once the deployment is complete, you will receive a service URL. Use it to access your deployed application.

### Part 2: Building and Deploying a Custom Image with Python

In this part, you will build a custom Docker image containing a Python application and deploy it to Cloud Run.

#### GUI Instructions:

1. Open the [Google Cloud Console](https://console.cloud.google.com/).

2. In the left navigation pane, go to "Cloud Build."

3. Click "Triggers" and create a new trigger linked to your source code repository. Configure it to build Docker images automatically when changes are pushed.

4. Commit a Python application code to your source code repository.

5. Once the trigger builds the Docker image, go to "Cloud Run."

6. Click "Create Service."

7. Choose a deployment platform (e.g., "Fully managed").

8. Click "Next."

9. Configure the service:
   - **Service Name**: Enter a name for your service.
   - **Deployment Platform**: Select "Fully managed."
   - **Region**: Choose a region.
   - **Authentication**: Leave it as "Allow unauthenticated invocations."
   - **Container Image**: Enter the URL of your custom Docker image.

10. Click "Next."

11. Review your configuration and click "Create" to deploy the service.

12. Once the deployment is complete, click the service URL to access your deployed Python application.

#### CLI Instructions:

1. Open Cloud Shell.

2. Create a Dockerfile for your Python application in your source code repository. Here's an example Dockerfile:

   ```Dockerfile
   # Use the official Python image as the base image
   FROM python:3.9-slim

   # Set the working directory to /app
   WORKDIR /app

   # Copy the current directory contents into the container at /app
   COPY . /app

   # Install any needed packages specified in requirements.txt
   RUN pip install -r requirements.txt

   # Make port 80 available to the world outside this container
   EXPOSE 80

   # Define environment variable
   ENV NAME World

   # Run app.py when the container launches
   CMD ["python", "app.py"]
   ```

3. Build and push the Docker image to Google Container Registry (GCR) using Cloud Build:

   ```bash
   docker build -t gcr.io/<PROJECT_ID>/<IMAGE_NAME>

   docker build -t gcr.io/compute-section/newimage .
   ```

   Replace `<PROJECT_ID>` with your GCP project ID and `<IMAGE_NAME>` with a name for your custom image.

4. Push the image to container registry
   ```bash
     docker push gcr.io/compute-section/newimage
   ```
5. Go to "Cloud Run" in the Cloud Console.

6. Run the following command to deploy your custom image:

   ```bash
   gcloud run deploy <SERVICE_NAME> \
     --image gcr.io/<PROJECT_ID>/<IMAGE_NAME> \
     --platform managed \
     --region <REGION>

   gcloud run deploy newservice --image gcr.io/compute-section/newimage --platform managed --region us-central1
   ```

   Replace `<SERVICE_NAME>` with a name for your service, `<PROJECT_ID>` with your GCP project ID, `<IMAGE_NAME>` with your custom image name, and `<REGION>` with your desired region.

6. Follow the prompts to allow unauthenticated invocations and confirm the deployment.

7. Once the deployment is complete, you will receive a service URL. Use it to access your deployed Python application.

### Part 3: Performing Traffic Splitting

In this part, you will learn how to perform traffic splitting between different versions of your application.

#### GUI Instructions:

1. Go to "Cloud Run" in the Cloud Console.

2. Click on your deployed service to open its details.

3. In the "Deployments" section, click "Edit & Deploy New Revision."

4. Deploy a new revision of your service with code changes or a new image.

5. After the new revision is deployed, go to the "Traffic" tab.

6. Adjust the traffic allocation between the existing revision and the new revision using the slider.

7. Click "Next" to review the configuration.

8. Click "Deploy" to perform traffic splitting.

9. Access your service URL to observe the traffic distribution.

#### CLI Instructions:

1. Go to "Cloud Run" in the Cloud Console.

2. Run the following command to deploy a new revision of your service:

   ```bash
   gcloud run deploy <SERVICE_NAME> \
     --image gcr.io/<PROJECT_ID>/<NEW_IMAGE_NAME> \
     --platform managed \
     --region <REGION>

   # Deploy "v1"
   gcloud run deploy v1 --image=gcr.io/PROJECT_ID/my-service:v1 --platform=managed --region=REGION

# Deploy "v2"
   gcloud run deploy v2 --image=gcr.io/PROJECT_ID/my-service:v2 --platform=managed --region=REGION

   ```

   Replace `<SERVICE_NAME>` with your service name, `<PROJECT_ID>` with your GCP project ID, `<NEW_IMAGE_NAME>` with the new image name, and `<REGION>` with your desired region.

3. To see the services running, run below command:-
```bash
   gcloud run services list
   gcloud run services describe newservice --region=us-central1
```
4. After the new revision is deployed, use the following command to adjust traffic allocation:

   ```bash
   gcloud run services update-traffic <SERVICE_NAME> \
     --to-latest
   ```
or 
```bash
   gcloud run services update-traffic my-service --to-revisions=v1=80,v2=20 --platform=managed --region=REGION

```

   Replace `<SERVICE_NAME>` with your service name.

5. You can check the traffice splitting by running below command:-
   ```bash
   gcloud run services describe my-service --platform=managed --region=REGION

   ```
6. Access your service URL to observe the traffic distribution between revisions.

## Conclusion

In this lab, you have learned how to deploy and manage containers using Google Cloud Run. You deployed a predefined Docker image, built and deployed a custom image with a Python application, and performed traffic splitting between different versions of your application. These skills
