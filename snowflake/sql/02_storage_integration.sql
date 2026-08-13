-- FinPulse — Storage Integration (Snowflake <-> ADLS Gen2)
-- This creates a trust relationship using Azure AD, so Snowflake never
-- needs your storage account keys.

USE ROLE ACCOUNTADMIN;

CREATE STORAGE INTEGRATION IF NOT EXISTS finpulse_azure_integration
    TYPE = EXTERNAL_STAGE
    STORAGE_PROVIDER = 'AZURE'
    ENABLED = TRUE
    AZURE_TENANT_ID = '<your-azure-tenant-id>'  -- az account show --query tenantId -o tsv
    STORAGE_ALLOWED_LOCATIONS = (
        'azure://<your-storage-account-name>.blob.core.windows.net/bronze/',
        'azure://<your-storage-account-name>.blob.core.windows.net/raw-streaming/'
    );

-- After running this, Snowflake generates an Azure AD app it uses to
-- authenticate. Retrieve it with:
DESC STORAGE INTEGRATION finpulse_azure_integration;
-- Look for AZURE_CONSENT_URL and AZURE_MULTI_TENANT_APP_NAME in the output.

-- Next manual step (one-time, in Azure Portal or CLI):
-- 1. Open the AZURE_CONSENT_URL from above, consent as your Azure AD admin
-- 2. Go to your storage account -> Access Control (IAM) -> Add role assignment
--    Role: Storage Blob Data Reader
--    Assign to: the Snowflake app (search by AZURE_MULTI_TENANT_APP_NAME)
--    Scope: the storage account (or narrow to bronze/raw-streaming containers)
