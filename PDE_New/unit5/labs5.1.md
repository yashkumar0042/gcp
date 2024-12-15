Here are some hands-on labs for optimizing resources in Google Cloud Platform (GCP), based on the considerations mentioned above:

### 1. **Lab: Right-Sizing Compute Resources in GCP**

**Objective**: Learn how to optimize compute resources for data processing jobs.

**Steps**:
1. **Create a Google Compute Engine instance**:
   - In the Google Cloud Console, navigate to **Compute Engine** > **VM instances**.
   - Click **Create Instance** and select the desired machine type. Try starting with a small machine type (e.g., `e2-micro`).
   - Choose the region and zone where the instance will be created.
   
2. **Test performance**:
   - SSH into the instance and run resource-intensive operations (e.g., `stress` command to load CPU and memory).
   - Monitor performance using **Google Cloud Monitoring** (formerly Stackdriver).

3. **Scale the VM**:
   - Resize the VM to a larger machine type (e.g., `n2-standard-4`).
   - Rerun the stress test and monitor the improved performance.

4. **Auto-Scaling Configuration**:
   - Use **Google Kubernetes Engine (GKE)** to create an auto-scaling cluster with a custom resource limit.
   - Create a simple application that simulates varying load and auto-scaling based on resource utilization.

**Lab Outcome**: Understand how to right-size your GCP compute resources based on performance and cost trade-offs.

---

### 2. **Lab: Cost Optimization Using Preemptible VMs**

**Objective**: Learn how to use preemptible VMs for cost-effective batch processing.

**Steps**:
1. **Create a Preemptible VM**:
   - In the **Google Cloud Console**, navigate to **Compute Engine** > **VM Instances**.
   - Click **Create Instance** and check the option **Preemptible** under the **Availability policy** section.
   - Choose a machine type and disk size based on your workload.

2. **Run a Job on the Preemptible VM**:
   - SSH into the preemptible VM and run a batch processing task (e.g., process a large dataset using Python or Spark).
   - Monitor the progress of the job and note the cost savings compared to a regular VM.

3. **Test VM Termination**:
   - Simulate the preemption by monitoring the VM status. Preemptible VMs can be terminated with a 30-second warning.
   - Use a **Cloud Function** or **Cloud Pub/Sub** to notify when a VM is about to be preempted.

**Lab Outcome**: Understand how preemptible VMs can significantly reduce costs for non-critical, batch processing jobs.

---

### 3. **Lab: Auto-Scaling with Google Kubernetes Engine (GKE)**

**Objective**: Learn how to configure auto-scaling in GKE for dynamically adjusting resources based on demand.

**Steps**:
1. **Create a GKE Cluster**:
   - Navigate to **Kubernetes Engine** > **Clusters** in the GCP Console.
   - Click **Create Cluster**, choose the standard mode, and configure the cluster to include multiple nodes with auto-scaling enabled.

2. **Deploy a Sample Application**:
   - Deploy a simple application (e.g., a web server using `nginx`) on the cluster.
   - Configure resource requests and limits for the pods.
   - Use **kubectl** to deploy the application.

3. **Simulate Load**:
   - Use a tool like **Apache JMeter** or **k6** to simulate varying levels of traffic on your application.
   - Monitor GKE’s auto-scaling behavior and observe the cluster adding or removing nodes based on the workload.

4. **Review Logs and Metrics**:
   - Use **Google Cloud Monitoring** to review auto-scaling events and resource utilization metrics.

**Lab Outcome**: Learn how to configure auto-scaling in GKE to manage resources dynamically based on application demand.

---

### 4. **Lab: Using BigQuery to Optimize Storage and Query Costs**

**Objective**: Optimize storage and queries in BigQuery to minimize costs.

**Steps**:
1. **Create a BigQuery Dataset**:
   - In the Google Cloud Console, navigate to **BigQuery**.
   - Create a new dataset and upload a large CSV file (e.g., a dataset with millions of rows) to the dataset.

2. **Partition and Cluster the Table**:
   - Create a partitioned table by choosing a date column for partitioning.
   - Optionally, apply clustering on frequently queried columns (e.g., `user_id`, `region`).
   
3. **Optimize Queries**:
   - Run some example queries on the dataset to observe the cost.
   - Use **Query Plan Explanation** to understand which columns are being scanned and how partitions are being used.
   - Modify the queries to take advantage of partitioning and clustering (e.g., filter on partitioned columns).
   
4. **Optimize Storage**:
   - Try using **PARQUET** or **ORC** format when uploading data instead of CSV to reduce storage costs.
   - Compare storage costs of different formats in BigQuery’s storage usage dashboard.

**Lab Outcome**: Learn how partitioning, clustering, and efficient file formats can help optimize BigQuery storage and query costs.

---

### 5. **Lab: Set Up High Availability for Business-Critical Data Processes**

**Objective**: Implement high-availability configurations for critical workloads in GCP.

**Steps**:
1. **Deploy a Cloud SQL Instance with High Availability**:
   - In the **Google Cloud Console**, navigate to **SQL** > **Instances**.
   - Create a new **Cloud SQL** instance with the **High Availability (HA) option** enabled.
   
2. **Deploy an Application Using Cloud SQL**:
   - Deploy a web application (e.g., a Flask app) in **Google App Engine** or **Compute Engine** that connects to the Cloud SQL instance.
   
3. **Test Failover**:
   - Simulate an outage by manually stopping the primary instance and observe the failover process.
   - Monitor the application's behavior during the failover and the time it takes for automatic recovery.
   
4. **Set Up Global Load Balancing**:
   - If deploying an application, configure **Global HTTP(S) Load Balancing** to route traffic to healthy instances, ensuring high availability for users worldwide.
   
**Lab Outcome**: Understand how to implement high availability for business-critical data services and applications in GCP.

---

### 6. **Lab: Dataproc for Job-Based Clusters**

**Objective**: Use Google Dataproc for cost-effective job-based cluster management.

**Steps**:
1. **Create a Dataproc Cluster**:
   - Navigate to **Dataproc** in the GCP Console and create a cluster with the required number of worker nodes.
   - Choose a machine type and set up the cluster for job processing.
   
2. **Run a Spark Job**:
   - Upload a sample dataset (e.g., a large CSV) to **Google Cloud Storage**.
   - Submit a **Spark** job on the Dataproc cluster to process the data (e.g., perform ETL or analysis).
   
3. **Terminate the Cluster After Completion**:
   - After the job completes, terminate the Dataproc cluster to avoid unnecessary charges for idle resources.

4. **Automate Cluster Creation and Deletion**:
   - Use **Cloud Functions** or **Cloud Scheduler** to automate the process of creating and terminating Dataproc clusters for recurring batch jobs.

**Lab Outcome**: Learn how to use job-based clusters with Google Dataproc for efficient batch processing and cost optimization.

---

### 7. **Lab: Use Preemptible VMs with Cloud Functions**

**Objective**: Integrate Preemptible VMs with Cloud Functions for automated scaling and cost savings.

**Steps**:
1. **Create a Preemptible VM**:
   - Create a preemptible VM in the **Google Cloud Console** and install the necessary tools (e.g., Python, Apache Spark).

2. **Create a Cloud Function**:
   - In **Cloud Functions**, create a function that triggers on specific events (e.g., when a file is uploaded to Cloud Storage).
   
3. **Automate VM Spin-Up and Termination**:
   - Write a Cloud Function to automatically start a preemptible VM when needed and terminate it once the processing job is complete.
   
4. **Monitor and Optimize**:
   - Use **Google Cloud Monitoring** to track VM status and ensure that Cloud Functions trigger appropriately without over-provisioning resources.

**Lab Outcome**: Understand how to automate the creation and termination of Preemptible VMs using Cloud Functions for cost optimization.

---

### Conclusion
These labs will help you gain practical experience with GCP's services and tools to optimize resource usage, reduce costs, ensure high availability, and handle job-based workloads efficiently. Completing these labs will enhance your understanding of GCP’s capabilities for managing large-scale data engineering tasks.
