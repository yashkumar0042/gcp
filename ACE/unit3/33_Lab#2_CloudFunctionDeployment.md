
### Lab: Deploying a Google Cloud Function (HTTP Trigger) in Python

**Objective:** Deploy a Google Cloud Function with an HTTP trigger using both the Google Cloud Console and the Google Cloud SDK.

**Prerequisites:**
- A Google Cloud Platform (GCP) account and project.
- Google Cloud SDK installed and configured.

#### Part 1: Deployment using Google Cloud Console (GUI)

**Step 1: Create a New Google Cloud Function**

1. Open the [Google Cloud Console](https://console.cloud.google.com/).

2. Select your project or create a new one.

3. In the left sidebar, navigate to "Cloud Functions."

4. Click the "Create Function" button.

5. Configure your function:
   - **Name:** my-http-function
   - **Memory:** 256 MiB
   - **Trigger:** HTTP trigger
   - **Source code:** Inline editor

6. In the "Inline editor" tab, replace the existing code with the following Python code:

   ```python
   def hello_http(request):
       return "Hello, Cloud Function!"
   ```

7. Click "Create."

**Step 2: Deploy the Function**

1. In the Cloud Function details page, click "Create" to deploy the function.

**Step 3: Test the Function**

1. Once deployed, click the function's URL to test it in your web browser or use a tool like `curl`.

#### Part 2: Deployment using Google Cloud SDK (CLI)

**Step 4: Deploy the Function Using CLI**

1. Open a terminal.

2. Use the following command to deploy the function using the Google Cloud SDK CLI. Replace `YOUR_PROJECT_ID` with your actual project ID.

   ```bash
   gcloud functions deploy my-http-function \
       --runtime python310 \
       --trigger-http \
       --allow-unauthenticated \
       --project YOUR_PROJECT_ID \
       --entry-point hello_http
   ```

   - `--runtime python310`: Specifies the Python runtime version.
   - `--trigger-http`: Configures an HTTP trigger.
   - `--allow-unauthenticated`: Allows unauthenticated access for testing purposes.
   - `--entry-point hello_http`: Specifies the Python function to be triggered.

3. After deploying, the CLI will display the function's URL. You can use `curl` or a web browser to test it.

#### Part 3: Cleanup

**Step 5: Delete the Cloud Function**

1. To delete the function created using the Google Cloud Console, go to the Cloud Function details page, click the "Delete" button, and confirm the deletion.

2. To delete the function created using the CLI, use the following command:

   ```bash
   gcloud functions delete my-http-function --project YOUR_PROJECT_ID
   ```

Congratulations! You've successfully deployed a Google Cloud Function using both the Google Cloud Console (GUI) and the Google Cloud SDK (CLI) with an HTTP trigger in Python. This lab provides a basic example, but you can expand on it to create more complex functions as needed.
