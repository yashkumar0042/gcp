Google Cloud Storage Transfer Service (STS)

The Storage Transfer Service (STS) in Google Cloud is designed to efficiently transfer data from external sources to Cloud Storage. It supports the following types of transfers:
	1.	Transfers from AWS S3 to Google Cloud Storage.
	2.	Transfers from an HTTP/HTTPS location to Google Cloud Storage.
	3.	Transfers from another Cloud Storage bucket.
	4.	Scheduled or one-time data transfers.

This service is ideal for migrating data, backing up data, or automating regular data synchronization.

Key Features:

	•	Scalable: Handles large-scale data transfers.
	•	Automated Scheduling: Schedule transfers on a recurring basis.
	•	Data Filtering: Options to include/exclude specific files based on criteria.
	•	Data Integrity: Provides options for data validation after transfer.

Lab Setup: Using Storage Transfer Service via GUI and CLI

Lab Scenario:

You want to copy data from an AWS S3 bucket or another Cloud Storage bucket to your own GCS bucket using Storage Transfer Service.

Option 1: Using Google Cloud Console (GUI)

Step 1: Enable Required APIs

	1.	Go to the Google Cloud Console.
	2.	Enable the Storage Transfer API.
	•	Search for “Storage Transfer API” and click Enable.

Step 2: Create a Destination GCS Bucket

	1.	Go to Cloud Storage → Buckets → Create Bucket.
	2.	Name your bucket (e.g., my-destination-bucket).
	3.	Choose a location and storage class.
	4.	Click Create.

Step 3: Set Up a Transfer Job

	1.	Go to Storage Transfer Service → Create Transfer Job.
	2.	Choose the source:
	•	For GCS to GCS transfer, select Google Cloud Storage.
	•	For AWS S3, select Amazon S3.
	•	For HTTP/HTTPS, select Web Location.
	3.	Enter the source bucket URI (e.g., gs://source-bucket-name).
	•	For AWS S3, provide the AWS S3 bucket name and authentication details.
	4.	Select the destination bucket (e.g., my-destination-bucket).
	5.	Set transfer options:
	•	Overwrite files if they already exist.
	•	Delete objects from the source after transferring (if needed).
	6.	Configure schedule options:
	•	Choose One-time or Recurring (daily, weekly).
	7.	Click Create to start the transfer job.

Step 4: Monitor the Transfer Job

	•	Go to Storage Transfer Service → Transfer Jobs.
	•	Check the status (Running, Completed, Failed).
	•	Review the transfer logs for detailed information.

Option 2: Using the Command Line Interface (CLI)

Step 1: Enable APIs

gcloud services enable storagetransfer.googleapis.com

Step 2: Create a Destination GCS Bucket

gsutil mb gs://my-destination-bucket

Step 3: Create a Transfer Job (GCS to GCS Transfer)

gcloud transfer jobs create \
    --source-bucket=source-bucket-name \
    --destination-bucket=my-destination-bucket \
    --description="GCS to GCS transfer job" \
    --schedule-start-date=2024-11-17 \
    --schedule-end-date=2024-11-18 \
    --overwrite-when=DIFFERENT

Parameters Explained:
	•	--source-bucket: Name of the source GCS bucket.
	•	--destination-bucket: Name of your destination GCS bucket.
	•	--schedule-start-date: Date to start the transfer.
	•	--schedule-end-date: Date to end the transfer.
	•	--overwrite-when: Specify whether to overwrite existing files (e.g., DIFFERENT, ALWAYS).

Step 4: Create a Transfer Job (AWS S3 to GCS Transfer)

gcloud transfer jobs create \
    --source-agent-pool=default \
    --source-s3-bucket=aws-s3-bucket-name \
    --destination-bucket=my-destination-bucket \
    --description="AWS S3 to GCS transfer job" \
    --aws-access-key-id=YOUR_AWS_ACCESS_KEY \
    --aws-secret-access-key=YOUR_AWS_SECRET_KEY \
    --region=us-west-1 \
    --schedule-start-date=2024-11-17

Parameters Explained:
	•	--source-s3-bucket: Name of the AWS S3 bucket.
	•	--aws-access-key-id and --aws-secret-access-key: AWS credentials.
	•	--region: AWS S3 bucket region.

Step 5: Monitor the Transfer Job

List and check the status of transfer jobs:

gcloud transfer jobs list
gcloud transfer jobs describe JOB_NAME

Best Practices

	1.	Use Filters: Utilize include/exclude filters for transferring only specific files.
	2.	Scheduling: Set up recurring transfers for regular data synchronization.
	3.	Data Validation: Enable data integrity checks for large or critical transfers.
	4.	Cost Management: Be aware of potential costs associated with data transfer, especially from external sources like AWS S3.

Would you like more details or assistance with a specific part of the process?
