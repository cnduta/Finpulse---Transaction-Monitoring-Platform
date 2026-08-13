-- Called by ADF's Stored Procedure activity after a successful Copy.
-- Advances the watermark only on success — this is what makes reruns safe.

CREATE PROCEDURE dbo.usp_update_watermark
    @source_name VARCHAR(100),
    @new_watermark_value VARCHAR(100)
AS
BEGIN
    UPDATE dbo.watermark_control
    SET last_loaded_value = @new_watermark_value,
        last_updated_at = SYSUTCDATETIME(),
        last_run_status = 'SUCCESS'
    WHERE source_name = @source_name;
END
