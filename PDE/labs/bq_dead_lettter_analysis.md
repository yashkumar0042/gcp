Creating a sample lab involves multiple steps, including setting up Google Cloud Storage, creating a Dataflow pipeline, and handling bad records. Below is a simplified example lab that you can follow to achieve this:

### Lab Steps:

#### 1. Set up Google Cloud Storage:

Create a bucket in Google Cloud Storage to store your CSV files.

```bash
gsutil mb gs://your_bucket_name
```

Upload a sample CSV file to your bucket.

```bash
gsutil cp sample_data.csv gs://your_bucket_name/
```

#### 2. Create a BigQuery Dataset and Table:

Create a BigQuery dataset.

```bash
bq mk your_dataset_name
```

Create a BigQuery table that matches your CSV file structure.
sample_data.csv
```bash
id,name,age,city
1,John,30,New York
2,Jane,25,San Francisco
3,Bob,35,Los Angeles
4,Alice,28,Chicago
```

```bash
bq load --autodetect --source_format=CSV your_dataset_name.your_table_name gs://your_bucket_name/sample_data.csv
```

#### 3. Create a Dead-letter Table:

Create a dataset for dead-letter tables.

```bash
bq mk your_dataset_name_deadletter
```

#### 4. Run a Dataflow Pipeline:

Create a Dataflow pipeline template (replace placeholders with your values).

```bash
python dataflow_pipeline.py \
  --project=your_project \
  --runner=DataflowRunner \
  --staging_location=gs://your_bucket_name/staging \
  --temp_location=gs://your_bucket_name/temp \
  --input=gs://your_bucket_name/sample_data.csv \
  --output=your_project:your_dataset_name.your_table_name \
  --deadletter_table=your_project:your_dataset_name_deadletter.your_deadletter_table
```

**dataflow_pipeline.py:**

```python
import apache_beam as beam
from apache_beam.options.pipeline_options import PipelineOptions

class ProcessCSV(beam.DoFn):
    def process(self, element):
        # Your data cleaning and transformation logic here
        # For simplicity, let's assume no transformation for this example
        yield element

def run(argv=None):
    pipeline_options = PipelineOptions(argv)
    p = beam.Pipeline(options=pipeline_options)

    input_file = "gs://your_bucket_name/sample_data.csv"
    output_table = "your_project:your_dataset_name.your_table_name"
    deadletter_table = "your_project:your_dataset_name_deadletter.your_deadletter_table"

    (p
     | 'ReadFromGCS' >> beam.io.ReadFromText(input_file)
     | 'TransformData' >> beam.ParDo(ProcessCSV())
     | 'WriteToBigQuery' >> beam.io.WriteToBigQuery(
         output_table,
         create_disposition=beam.io.BigQueryDisposition.CREATE_IF_NEEDED,
         write_disposition=beam.io.BigQueryDisposition.WRITE_APPEND)
     )

    result = p.run()
    result.wait_until_finish()

if __name__ == '__main__':
    run()
```

This example assumes a simple data cleaning and transformation process. You can modify the `ProcessCSV` class to implement your specific logic.

#### 5. Monitor the Dataflow Job:

Monitor the Dataflow job in the Google Cloud Console or use the command line.

```bash
gcloud dataflow jobs list
```

#### 6. Check Bad Records:

Check the dead-letter table for any records that couldn't be processed.

```bash
bq query --nouse_legacy_sql 'SELECT * FROM your_project:your_dataset_name_deadletter.your_deadletter_table'
```

This sample lab provides a basic framework for handling CSV data in Google Cloud Storage, cleaning it with a Dataflow pipeline, and storing it in BigQuery. Customize the pipeline and scripts based on your specific data and requirements.
