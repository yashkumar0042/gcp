##  ###############################################################################
##
##   NAME:           main.py (ssot-cicd-automation)
##
##   DESCRIPTION:    This script will create datasets and tables tf configuration file and table schema json file by taking input from excel file.
##
##   EXIT CODES:
##                   100 - Exception raised in automating_tf_and_schema_file_creation function.
##                   101 - Exception raised in datasets_tf_config function.
##                   102 - Exception raised in tables_tf_config function.
##                   103 - Exception raised in schema_json_file function.
##                   104 - Exception raised in upload_data function.
##
##  ###############################################################################
##  Change History
##  ###############################################################################
##  ChangeDate/Version   Author				Description
##  ###############################################################################


from google.cloud import bigquery
from google.cloud import storage
from datetime import datetime
from google.cloud import logging as glogging
import logging
###### pip install xlrd==1.2.0 ########
import xlrd
import os
import io
import re
import json

client = bigquery.Client()
storage_client = storage.Client()

project_id = 'var.project'

log_client = glogging.Client()
log_client.setup_logging()
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

timestamp =  str(datetime.now().strftime("%Y%m%d_%H%M%S%f"))

def upload_data(bucket_name, source_file_name, destination_blob_name):
    try:    
        storage_client = storage.Client()
        bucket = storage_client.bucket(bucket_name)
        blob = bucket.blob(destination_blob_name)
        blob.upload_from_filename(source_file_name)
        logger.info(
            f"File {source_file_name} uploaded to {destination_blob_name}."
        )
        os.remove(source_file_name)
    except Exception as e:
        exit_code = 104
        error_msg = "Exception raised while running upload_data function : "+str(e)
        logger.exception(error_msg)
        raise Exception(error_msg)

def tables_tf_config(dataset_id,table_list):
    try:
        for table_id in table_list:
            table = client.get_table(f'{project_id}.{dataset_id}.{table_id}')  # Make an API request.

            table_expiration = table.expires
            if table_expiration is None :
                table_expiration = 'null'

            clustering = table.clustering_fields
            clustering = json.dumps(clustering)
            if clustering is None :
                clustering = 'null'
            try: 
                if table.time_partitioning.field:
                    require_partition_filter = table.time_partitioning.require_partition_filter 
                    if require_partition_filter is None :
                        require_partition_filter = 'null'
                    time_partition_description = f'''time_partitioning =  {{
        type           = "{table.time_partitioning.type_}"
        field          = "{table.time_partitioning.field}"
        expiration_ms  = {table.time_partitioning.expiration_ms}
        require_partition_filter = {require_partition_filter}        
        }}'''       
            except AttributeError:
                time_partition_description = "time_partitioning =  null"

            try: 
                if table.range_partitioning.field:
                    require_partition_filter = table.range_partitioning.require_partition_filter 
                    if require_partition_filter is None :
                        require_partition_filter = 'null'        

                    range_partitioning_description = f'''range_partitioning =  {{
        field          = "{table.range_partitioning.field}"
        require_partition_filter = {require_partition_filter}
          range = {{
          start    = {table.range_partitioning.range_.start}
          end      = {table.range_partitioning.range_.end}
          interval = {table.range_partitioning.range_.interval}
          }}                
        }}'''
            except AttributeError:
                range_partitioning_description = "range_partitioning =  null"
                        
            with open("/tmp/datasets_tables_tf_config.tf","a") as f:
                f.write(f'''    {{
      table_id            = "{table_id}"
      dataset_id          = "{dataset_id}"
      schema              = "${{path.module}}/json/{dataset_id}/{table_id}.json"
      {range_partitioning_description}
      expiration_time     = {table_expiration}
      deletion_protection = false
      {time_partition_description}
      clustering = {clustering}
      labels = merge(var.baselabels, {{ resource_name = lower("{table_id}") }})      
    }},
''')
            logger.info(f"tf config for table {table_id} of dataset {dataset_id} is created in /tmp/datasets_tables_tf_config.tf")
    except Exception as e:
        exit_code = 102
        error_msg = "Exception raised while running tables_tf_config function : "+str(e)
        logger.exception(error_msg)
        raise Exception(error_msg)
    
def datasets_tf_config(dataset_id):
    try:
        with open("/tmp/datasets_tables_tf_config.tf","a") as f:  
            f.write(f'''    {{
      dataset_id    = "{dataset_id}"
      friendly_name = "dataset for {dataset_id}"
      location      = var.location
      labels        = merge(var.baselabels, {{ resource_name = "{dataset_id}"}})
    }},
''')
            logger.info(f"tf config for dataset {dataset_id} is created in /tmp/datasets_tables_tf_config.tf")
    except Exception as e:
        exit_code = 101
        error_msg = "Exception raised while running datasets_tf_config function : "+str(e)
        logger.exception(error_msg)
        raise Exception(error_msg)

def schema_json_file(dataset_id,table_list,bucket_name,file_name_base):
    try:
        bucket = storage_client.bucket(bucket_name)
        for table_id in table_list:
            dataset_ref = client.dataset(dataset_id, project=project_id)
            table_ref = dataset_ref.table(table_id)
            table = client.get_table(table_ref)

            f = io.StringIO("")
            client.schema_to_json(table.schema, f)
            blob = bucket.blob(f'table_schema_jsons/{file_name_base}_{timestamp}/{dataset_id}/{table_id}.json')
            with blob.open("w") as file:
                file.write(re.sub('"mode": "NULLABLE",',"",f.getvalue()))
                logger.info(f"table_schema_jsons/{file_name_base}_{timestamp}/{dataset_id}/{table_id}.json created for table {table_id} of dataset {dataset_id}")
    except Exception as e:
        exit_code = 103
        error_msg = "Exception raised while running schema_json_file function : "+str(e)
        logger.exception(error_msg)
        raise Exception(error_msg)


def automating_tf_and_schema_file_creation(data,context):
    try:
        bucket_name = data['bucket']
        file_name = data['name']
        file_name_base = '.'.join(file_name.split('.')[:-1])
        file_name_extn = file_name.split('.')[-1]

        if ('/') not in file_name and (file_name_extn == 'xlsx' or file_name_extn == 'xls'):

            logger.info(f"This script will create table and dataset tf and schema json file from Sandbox Project with Project_ID:{project_id}")

            bucket = storage_client.bucket(bucket_name)
            blob = bucket.blob(f'{file_name}')
            blob.download_to_filename(f'/tmp/{file_name}')
            wb = xlrd.open_workbook(f'/tmp/{file_name}')
            sheet = wb.sheet_by_index(0)
            num_dataset = 0
            for row_num in range(sheet.nrows):
                row_value = sheet.row_values(row_num)
                if row_value[0].upper() != 'DATASET' and row_value[0] is not None:
                    num_dataset = num_dataset + 1
                    if num_dataset == 1:
                        with open("/tmp/datasets_tables_tf_config.tf","a") as f:
                            f.write(f'''module "ssot_raw_datasets" {{
  source = "../reusable/tfrm-bigquery"

  project_id                = var.project
  delete_content_on_destroy = true
  deletion_protection       = false

  datasets = [
''')
                    datasets_tf_config(row_value[0])
                elif row_value[0].upper() != 'DATASET' and row_value[0] is None:
                    logger.info(f"No dataset mentioned in {file_name} for dataset tf config")
            if num_dataset >= 1:
                with open("/tmp/datasets_tables_tf_config.tf","r+") as f:     
                    text = re.sub("[,]$","",f.read()) 
                    with open("/tmp/datasets_tables_tf_config.tf","w+") as f:
                        f.write(text)
                with open("/tmp/datasets_tables_tf_config.tf","a") as f:
                    f.write(f'''  ]
}}
''')    
            num_table = 0      
            for row_num in range(sheet.nrows):
                row_value = sheet.row_values(row_num)
                if row_value[0].upper() != 'DATASET' and row_value[0] is not None:
                    if row_value[1] != '':
                        num_table = num_table + 1
                        if num_table == 1:
                            with open("/tmp/datasets_tables_tf_config.tf","a") as f:
                                f.write(f'''module "ssot_raw_datasets_tables" {{
  source                    = "../reusable/tfrm-bigquery"
  project_id                = var.project
  delete_content_on_destroy = false
  #depends_on = [module.ssot_raw_datasets]
  deletion_protection = false

  tables = [
''')       
                        tables_tf_config(row_value[0],row_value[1].split(","))
                    else:
                        logger.info(f"No table mentioned for dataset {row_value[0]}")
                elif row_value[0].upper() != 'DATASET' and row_value[0] is None:
                    logger.info(f"No dataset mentioned in {file_name} for table tf config")
            if num_table >= 1:
                with open("/tmp/datasets_tables_tf_config.tf","r+") as f:     
                    text = re.sub("[,]$","",f.read()) 
                    with open("/tmp/datasets_tables_tf_config.tf","w+") as f:
                        f.write(text)
                with open("/tmp/datasets_tables_tf_config.tf","a") as f:
                    f.write(f'''  ]
}}
''')
            upload_data(bucket_name,"/tmp/datasets_tables_tf_config.tf",f"datasets_tables_tf_config/{file_name_base}_{timestamp}/datasets_tables_tf_config.tf")        
            for row_num in range(sheet.nrows):
                row_value = sheet.row_values(row_num)
                if row_value[0].upper() != 'DATASET' and row_value[0] is not None:
                    if row_value[1] != '':
                        schema_json_file(row_value[0],row_value[1].split(","),bucket_name,file_name_base)
                    else:
                        logger.info(f"No table mentioned for dataset {row_value[0]}")
                elif row_value[0].upper() != 'DATASET' and row_value[0] is None:
                    logger.info(f"No dataset mentioned in {file_name} for table schema json")

        elif ('table_schema_jsons') in file_name or ('datasets_tables_tf_config') in file_name:
            logger.info(f"{file_name} is a script generated file")
        else:
            logger.info(f"{file_name} is either not in the root folder or not in supported format (.xlsx and .xls)")
    except Exception as e:
        exit_code = 100
        error_msg = "Exception raised while running automating_tf_and_schema_file_creation function : "+str(e)
        logger.exception(error_msg)
        raise Exception(error_msg)
