### Migrating Data from Google Cloud Storage (GCS) to BigQuery

Migrating data from GCS to BigQuery is a common task in data engineering. Here’s a step-by-step guide, covering both the **manual process** via the BigQuery UI and the **automated process** using the **GCP CLI**, **bq command-line tool**, and **Python SDK**.

### **Prerequisites**
1. Enable the **BigQuery API** and **Cloud Storage API**:
   ```bash
   gcloud services enable bigquery.googleapis.com
   gcloud services enable storage.googleapis.com
   ```
2. Set up permissions:
   - Ensure that your Google Cloud Service Account has the following roles:
     - `roles/bigquery.dataEditor`
     - `roles/storage.objectViewer`
   - Grant these roles using:
     ```bash
     gcloud projects add-iam-policy-binding your-project-id \
         --member="serviceAccount:your-service-account@your-project-id.iam.gserviceaccount.com" \
         --role="roles/bigquery.dataEditor"

     gcloud projects add-iam-policy-binding your-project-id \
         --member="serviceAccount:your-service-account@your-project-id.iam.gserviceaccount.com" \
         --role="roles/storage.objectViewer"
     ```

### **Step 1: Prepare Data in GCS**
Upload your data file (e.g., `data.csv`) to a GCS bucket.

```bash
gsutil cp data.csv gs://your-bucket-name/data.csv
```

### **Step 2: Create a BigQuery Dataset**
Create a dataset in BigQuery where the table will be stored.

```bash
bq mk --dataset your-project-id:your_dataset
```

### **Step 3: Load Data from GCS to BigQuery Table**
#### **Option 1: Using the BigQuery UI**
1. Open the BigQuery Console: [BigQuery UI](https://console.cloud.google.com/bigquery).
2. Click on your dataset and select **Create Table**.
3. In the **Source** section:
   - Select **Google Cloud Storage** as the source.
   - Enter the GCS URI (e.g., `gs://your-bucket-name/data.csv`).
   - Choose the file format (e.g., CSV, JSON, Avro, Parquet).
4. In the **Destination** section:
   - Specify the dataset and table name.
   - Select the write preference (Append, Overwrite, etc.).
5. Define the schema manually or let BigQuery auto-detect it.
6. Click **Create Table** to start the import.

#### **Option 2: Using `bq` Command-Line Tool**
```bash
bq load \
--source_format=CSV \
--autodetect \
your_dataset.your_table \
gs://your-bucket-name/data.csv
```

**Parameters**:
- `--source_format`: Specifies the file format (CSV, JSON, AVRO, PARQUET, etc.).
- `--autodetect`: Automatically detects the schema. You can also specify the schema manually.

#### **Option 3: Using Python SDK**
```python
from google.cloud import bigquery

# Initialize BigQuery client
client = bigquery.Client()

# Define dataset and table details
dataset_id = "your-project-id.your_dataset"
table_id = "your_table"

# Define GCS URI
gcs_uri = "gs://your-bucket-name/data.csv"

# Define job configuration
job_config = bigquery.LoadJobConfig(
    source_format=bigquery.SourceFormat.CSV,
    skip_leading_rows=1,
    autodetect=True,
)

# Load data from GCS to BigQuery
load_job = client.load_table_from_uri(
    gcs_uri, f"{dataset_id}.{table_id}", job_config=job_config
)

# Wait for the job to complete
load_job.result()
print(f"Data loaded to {dataset_id}.{table_id} successfully!")
```

### **Step 4: Verify the Data in BigQuery**
Run a simple query to check the loaded data.

```sql
SELECT * FROM your_dataset.your_table LIMIT 10;
```

### **Best Practices**
1. **Partitioned Tables**: Use partitioned tables in BigQuery for efficient querying if your data is large and time-based.
2. **Schema Management**: Define the schema explicitly if your data structure is complex to avoid issues with autodetection.
3. **Data Validation**: Validate the loaded data using COUNT and other checks to ensure data integrity.

### **Automating the Process with Cloud Functions or Cloud Composer**
You can automate the data migration process using:
- **Cloud Functions**: Triggered whenever a new file is uploaded to GCS.
- **Cloud Composer (Airflow)**: For more complex ETL workflows.

Would you like a sample automation setup or have any specific questions about this process?
