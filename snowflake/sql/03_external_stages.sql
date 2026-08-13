-- FinPulse — External Stages
USE ROLE ACCOUNTADMIN;
USE DATABASE finpulse_db;
USE SCHEMA raw;

-- File formats
CREATE FILE FORMAT IF NOT EXISTS avro_format TYPE = 'AVRO';
CREATE FILE FORMAT IF NOT EXISTS json_format TYPE = 'JSON' STRIP_OUTER_ARRAY = TRUE;

-- Stage pointing at the streaming (Event Hubs Capture) container
CREATE STAGE IF NOT EXISTS stg_raw_streaming
    URL = 'azure://<your-storage-account-name>.blob.core.windows.net/raw-streaming/'
    STORAGE_INTEGRATION = finpulse_azure_integration
    FILE_FORMAT = avro_format;

-- Stage pointing at the batch (ADF) container
CREATE STAGE IF NOT EXISTS stg_bronze_batch
    URL = 'azure://<your-storage-account-name>.blob.core.windows.net/bronze/'
    STORAGE_INTEGRATION = finpulse_azure_integration
    FILE_FORMAT = json_format;

-- Sanity check: list files Snowflake can currently see in each stage
LIST @stg_raw_streaming;
LIST @stg_bronze_batch;
