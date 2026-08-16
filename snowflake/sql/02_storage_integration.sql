-- FinPulse — Storage Integration (Snowflake <-> ADLS Gen2)
USE ROLE ACCOUNTADMIN;

CREATE STORAGE INTEGRATION IF NOT EXISTS finpulse_azure_integration
    TYPE = EXTERNAL_STAGE
    STORAGE_PROVIDER = 'AZURE'
    ENABLED = TRUE
    AZURE_TENANT_ID = '528e985d-a258-43e8-b8b6-f006d2b87a96'
    STORAGE_ALLOWED_LOCATIONS = (
        'azure://finpulsesadevkaqn4gvdlf.blob.core.windows.net/bronze/',
        'azure://finpulsesadevkaqn4gvdlf.blob.core.windows.net/raw-streaming/'
    );

DESC STORAGE INTEGRATION finpulse_azure_integration;

-- Manual one-time steps required after running the above:
-- 1. Open AZURE_CONSENT_URL, sign in as Azure AD admin, accept consent
--    (may need /adminconsent variant + can take 1-2 hours for the
--    service principal to actually appear in the tenant)
-- 2. Storage account -> Access Control (IAM) -> Add role assignment
--    Role: Storage Blob Data Reader
--    Assign to: the AZURE_MULTI_TENANT_APP_NAME service principal
-- 3. If LIST on a stage fails with AuthorizationPermissionMismatch even
--    after the role shows as assigned, DROP and recreate the stage --
--    this forced a fresh permission evaluation and resolved it here.
