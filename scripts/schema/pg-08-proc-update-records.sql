-- ============================================================
-- Stored procedure: claims.update_records
-- Updates 10 rows in each claims table per call.
--   tbl_claimant  → update phone + status on oldest 10 non-deleted rows
--   tbl_claim     → update status + amount on oldest 10 non-deleted rows
--   tbl_work_item → update priority + status on oldest 10 non-deleted rows
-- All updated rows share the same run_id and batch_id.
-- ============================================================

CREATE OR REPLACE PROCEDURE claims.update_records()
LANGUAGE plpgsql
AS $$
DECLARE
    v_run_id   UUID := gen_random_uuid();
    v_batch_id UUID := gen_random_uuid();
    v_started  TIMESTAMPTZ := NOW();
BEGIN
    -- --------------------------------------------------------
    -- UPDATE 10 claimants
    -- --------------------------------------------------------
    UPDATE claims.tbl_claimant
    SET
        phone      = '+1-555-' || lpad((floor(random()*9000+1000)::INT)::TEXT,4,'0'),
        status     = CASE WHEN status = 'active' THEN 'under_review' ELSE 'active' END,
        updated_at = NOW(),
        run_id     = v_run_id,
        batch_id   = v_batch_id
    WHERE claimant_id IN (
        SELECT claimant_id FROM claims.tbl_claimant
        WHERE is_deleted = FALSE
        ORDER BY claimant_id
        LIMIT 10
    );

    -- --------------------------------------------------------
    -- UPDATE 10 claims
    -- --------------------------------------------------------
    UPDATE claims.tbl_claim
    SET
        status     = CASE
                         WHEN status = 'open'        THEN 'in_review'
                         WHEN status = 'in_review'   THEN 'pending_approval'
                         ELSE 'open'
                     END,
        amount     = round((amount * (0.9 + random()*0.2))::NUMERIC, 2),
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
    -- UPDATE 10 work items
    -- --------------------------------------------------------
    UPDATE claims.tbl_work_item
    SET
        priority   = CASE
                         WHEN priority = 'normal' THEN 'high'
                         WHEN priority = 'high'   THEN 'urgent'
                         ELSE 'normal'
                     END,
        status     = CASE
                         WHEN status = 'pending'     THEN 'in_progress'
                         WHEN status = 'in_progress' THEN 'awaiting_review'
                         ELSE 'pending'
                     END,
        updated_at = NOW(),
        run_id     = v_run_id,
        batch_id   = v_batch_id
    WHERE work_item_id IN (
        SELECT work_item_id FROM claims.tbl_work_item
        WHERE is_deleted = FALSE
        ORDER BY work_item_id
        LIMIT 10
    );

    RAISE NOTICE 'update_records complete — run_id: %, batch_id: %, started: %',
        v_run_id, v_batch_id, v_started;
END;
$$;
