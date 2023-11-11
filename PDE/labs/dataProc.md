*Data Proc Lab with PySpark*

**Step 1: Set Up Your Google Cloud Project**

Make sure you have a Google Cloud Platform account and a project set up. You can create a new project through the [Google Cloud Console](https://console.cloud.google.com/).

**Step 2: Enable the Dataproc API**

Navigate to the [APIs & Services > Dashboard](https://console.cloud.google.com/apis/dashboard) in the Google Cloud Console. Search for "Dataproc API" and enable it for your project.

**Step 3: Install and Configure Google Cloud SDK**

Make sure you have the [Google Cloud SDK](https://cloud.google.com/sdk) installed on your local machine. Authenticate your account and set the default project using the following commands:

```bash
gcloud auth login
gcloud config set project YOUR_PROJECT_ID
```

Replace `YOUR_PROJECT_ID` with the ID of your Google Cloud project.

**Step 4: Create a Google Cloud Storage Bucket**

Create a Cloud Storage bucket to store input data, output, and other artifacts. Replace `YOUR_BUCKET_NAME` with a unique name for your bucket.

```bash
gsutil mb -c regional -l us-central1 gs://YOUR_BUCKET_NAME/
```

**Step 5: Prepare Your Data**

Upload your data to the Cloud Storage bucket. For this example, let's assume you have a text file named `input.txt`. Upload it to your bucket:

```bash
gsutil cp input.txt gs://YOUR_BUCKET_NAME/input/
```

**Step 6: Create a Dataproc Cluster**

Now, it's time to create a Dataproc cluster. Replace `YOUR_CLUSTER_NAME` with a name for your cluster.

```bash
gcloud dataproc clusters create YOUR_CLUSTER_NAME \
    --region=us-central1 \
    --num-workers=2 \
    --master-machine-type=n1-standard-2 \
    --worker-machine-type=n1-standard-2
```

This command creates a Dataproc cluster with a master node and two worker nodes.

**Step 7: Submit a Spark Job**

Let's create a simple Spark job in Python. Create a Python script (e.g., `spark_job.py`) with the following content:

```python
from pyspark.sql import SparkSession

if __name__ == "__main__":
    # Create a Spark session
    spark = SparkSession.builder.appName("example-dataproc").getOrCreate()

    # Read data from Cloud Storage
    input_data = "gs://YOUR_BUCKET_NAME/input/input.txt"
    df = spark.read.text(input_data)

    # Perform a simple transformation (e.g., count lines)
    line_count = df.count()

    # Print the result
    print(f"Number of lines in the input file: {line_count}")

    # Write the result to Cloud Storage
    output_data = "gs://YOUR_BUCKET_NAME/output/output.txt"
    df.write.text(output_data)

    # Stop the Spark session
    spark.stop()
```

**Step 8: Upload the Spark Job to Cloud Storage**

Upload the Python script to your Cloud Storage bucket:

```bash
gsutil cp spark_job.py gs://YOUR_BUCKET_NAME/scripts/
```

**Step 9: Submit the Spark Job to Dataproc**

Submit the Spark job to the Dataproc cluster:

```bash
gcloud dataproc jobs submit pyspark \
    gs://YOUR_BUCKET_NAME/scripts/spark_job.py \
    --cluster=YOUR_CLUSTER_NAME
```

This command submits the Spark job to the Dataproc cluster, and you should see the output in the console.

**Step 10: Inspect Results**

You can check the results by looking at the output in Cloud Storage:

```bash
gsutil cat gs://YOUR_BUCKET_NAME/output/output.txt/part-*
```

This will display the output of your Spark job.

**Step 11: Delete the Dataproc Cluster**

After completing your work, it's important to delete the Dataproc cluster to avoid incurring unnecessary charges:

```bash
gcloud dataproc clusters delete YOUR_CLUSTER_NAME --region=us-central1
```

This example provides a basic walkthrough of using Google Cloud Dataproc to process data using Apache Spark. Depending on your specific use case, you may need to customize the Spark job and cluster configuration accordingly.
