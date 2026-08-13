-- FinPulse — CDC End-to-End Test
-- Run these steps manually, checking results between each one.

-- STEP 1: Confirm baseline state
SELECT * FROM finpulse_db.staging.accounts_current;
-- Expect: empty, or whatever the last Task run already processed

-- STEP 2: Trigger a real UPDATE on the source table
UPDATE finpulse_db.raw.accounts_master
SET country = 'UK', updated_at = CURRENT_TIMESTAMP()
WHERE account_id = 'ACC10001';
-- Simulates: "Jane Wanjiru" relocating from Kenya to UK

-- STEP 3: Confirm the Stream captured it (run BEFORE the Task consumes it)
SELECT * FROM finpulse_db.raw.stream_accounts_master;
-- Expect: rows showing the old and new values for ACC10001,
-- with METADATA$ACTION = 'DELETE' (old row) and 'INSERT' (new row)

-- STEP 4: Manually trigger the task now instead of waiting 5 minutes
EXECUTE TASK finpulse_db.raw.task_process_account_changes;

-- STEP 5: Confirm the merge worked
SELECT * FROM finpulse_db.staging.accounts_current WHERE account_id = 'ACC10001';
-- Expect: country = 'UK'

-- STEP 6: Confirm the stream is now empty again (fully consumed)
SELECT * FROM finpulse_db.raw.stream_accounts_master;
-- Expect: no rows

-- STEP 7 (ties back to Phase 4): if your dbt snapshot source were built off
-- accounts_current instead of silver_transactions, running `dbt snapshot`
-- now would close out the old SCD2 row and insert a new one reflecting
-- country = 'UK'. This is the exact Day 5 test case for your RUNLOG.
