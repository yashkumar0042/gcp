Practical example for a Hadoop lab on Google Cloud Dataproc. In this lab, we'll perform a WordCount operation on a text file using Hadoop MapReduce.

**Lab Objective:** Perform WordCount on a sample text file using Hadoop MapReduce on a Google Cloud Dataproc cluster.

### Step 1: Set Up Your Google Cloud Project

Ensure you have a Google Cloud Platform account and a project set up.

### Step 2: Enable the Dataproc API

Enable the Dataproc API for your project in the Google Cloud Console.

### Step 3: Install and Configure Google Cloud SDK

Install the Google Cloud SDK on your local machine, authenticate your account, and set the default project.

```bash
gcloud auth login
gcloud config set project your-project-id
```

### Step 4: Create a Google Cloud Storage Bucket

Create a Cloud Storage bucket to store input data and output.

```bash
gsutil mb -c regional -l us-central1 gs://hadoop-lab-bucket/
```

### Step 5: Prepare Your Data

Create a sample text file named `sample.txt` with some content and upload it to your Cloud Storage bucket.

```bash
echo "Hello Hadoop, this is a Hadoop lab. Hadoop is powerful!" > sample.txt
gsutil cp sample.txt gs://hadoop-lab-bucket/input/
```

### Step 6: Create a Dataproc Cluster with Hadoop

Create a Dataproc cluster named `hadoop-lab-cluster` with Hadoop installed.

```bash
gcloud dataproc clusters create hadoop-lab-cluster \
    --region=us-central1 \
    --num-workers=2 \
    --master-machine-type=n1-standard-2 \
    --worker-machine-type=n1-standard-2 \
    --initialization-actions gs://dataproc-initialization-actions/hadoop/hadoop.sh
```

### Step 7: Access the Hadoop Cluster

SSH into the master node to access the Hadoop web interfaces.

```bash
gcloud compute ssh --project=your-project-id \
    --zone=us-central1-a \
    --ssh-flag="-D" --ssh-flag="10000" --ssh-flag="-N" "hadoop-lab-cluster-m"
```

### Step 8: Explore Hadoop Web Interfaces

Open a web browser and navigate to:

- Hadoop Resource Manager: [http://localhost:8088/](http://localhost:8088/)
- Hadoop NameNode: [http://localhost:9870/](http://localhost:9870/)

### Step 9: Run a Hadoop Job

Run the WordCount example on the sample text file.

```bash
hadoop jar /usr/lib/hadoop-mapreduce/hadoop-mapreduce-examples.jar wordcount \
    gs://hadoop-lab-bucket/input/sample.txt \
    gs://hadoop-lab-bucket/output/
```

### Step 10: Check the Results

Check the WordCount result in Cloud Storage.

```bash
gsutil cat gs://hadoop-lab-bucket/output/part-r-00000
```

**Expected Output:**
```
Hadoop       2
Hello        1
is           1
lab.         1
lab.         1
powerful!    1
this         1
```

### Step 11: Delete the Dataproc Cluster

After completing the lab, delete the Dataproc cluster to avoid charges.

```bash
gcloud dataproc clusters delete hadoop-lab-cluster --region=us-central1
```

This example demonstrated setting up a Hadoop lab on Google Cloud Dataproc, running a WordCount job, and checking the results. Adjustments can be made based on your specific data and requirements.
