-- FinPulse — External Stages
USE ROLE ACCOUNTADMIN;
USE DATABASE finpulse_db;
USE SCHEMA raw;

CREATE FILE FORMAT IF NOT EXISTS avro_format TYPE = 'AVRO';
CREATE FILE FORMAT IF NOT EXISTS json_format TYPE = 'JSON' STRIP_OUTER_ARRAY = TRUE;

CREATE STAGE IF NOT EXISTS stg_raw_streaming
    URL = 'azure://finpulsesadevkaqn4gvdlf.blob.core.windows.net/raw-streaming/'
    STORAGE_INTEGRATION = finpulse_azure_integration
    FILE_FORMAT = avro_format;

CREATE STAGE IF NOT EXISTS stg_bronze_batch
    URL = 'azure://finpulsesadevkaqn4gvdlf.blob.core.windows.net/bronze/'
    STORAGE_INTEGRATION = finpulse_azure_integration
    FILE_FORMAT = json_format;

LIST @stg_raw_streaming;
LIST @stg_bronze_batch;
