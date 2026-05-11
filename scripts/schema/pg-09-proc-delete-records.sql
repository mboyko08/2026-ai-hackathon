-- ============================================================
-- Stored procedure: claims.delete_records
-- Soft-deletes 10 rows per claims table per call
-- (sets is_deleted = TRUE, does not physically remove rows).
--   tbl_work_item → soft-delete oldest 10 non-deleted work items first
--   tbl_claim     → soft-delete oldest 10 non-deleted claims next
--   tbl_claimant  → soft-delete oldest 10 non-deleted claimants last
-- Reverse FK order to avoid constraint violations.
-- All deleted rows share the same run_id and batch_id.
-- ============================================================

CREATE OR REPLACE PROCEDURE claims.delete_records()
LANGUAGE plpgsql
AS $$
DECLARE
    v_run_id   UUID := gen_random_uuid();
    v_batch_id UUID := gen_random_uuid();
    v_started  TIMESTAMPTZ := NOW();
BEGIN
    -- --------------------------------------------------------
    -- SOFT-DELETE 10 work items (child of claim, delete first)
    -- --------------------------------------------------------
    UPDATE claims.tbl_work_item
    SET
        is_deleted = TRUE,
        status     = 'cancelled',
        updated_at = NOW(),
        run_id     = v_run_id,
        batch_id   = v_batch_id
    WHERE work_item_id IN (
        SELECT work_item_id FROM claims.tbl_work_item
        WHERE is_deleted = FALSE
        ORDER BY work_item_id
        LIMIT 10
    );

    -- --------------------------------------------------------
    -- SOFT-DELETE 10 claims (child of claimant, delete second)
    -- --------------------------------------------------------
    UPDATE claims.tbl_claim
    SET
        is_deleted = TRUE,
        status     = 'closed',
        updated_at = NOW(),
        run_id     = v_run_id,
        batch_id   = v_batch_id
    WHERE claim_id IN (
        SELECT claim_id FROM claims.tbl_claim
        WHERE is_deleted = FALSE
        ORDER BY claim_id
        LIMIT 10
    );

    -- --------------------------------------------------------
    -- SOFT-DELETE 10 claimants (parent, delete last)
    -- --------------------------------------------------------
    UPDATE claims.tbl_claimant
    SET
        is_deleted = TRUE,
        status     = 'inactive',
        updated_at = NOW(),
        run_id     = v_run_id,
        batch_id   = v_batch_id
    WHERE claimant_id IN (
        SELECT claimant_id FROM claims.tbl_claimant
        WHERE is_deleted = FALSE
        ORDER BY claimant_id
        LIMIT 10
    );

    RAISE NOTICE 'delete_records complete — run_id: %, batch_id: %, started: %',
        v_run_id, v_batch_id, v_started;
END;
$$;
