-- ============================================================
-- Task 01 — PostgreSQL OLTP Schema: claims.tbl_work_item
-- Database: db-oltp-pfl-1
-- ============================================================

CREATE TABLE IF NOT EXISTS claims.tbl_work_item (
    work_item_id  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    claim_id      BIGINT      NOT NULL REFERENCES claims.tbl_claim (claim_id),
    assigned_to   TEXT,
    priority      TEXT        NOT NULL DEFAULT 'normal',
    status        TEXT        NOT NULL DEFAULT 'pending',
    description   TEXT,
    due_date      DATE,
    is_deleted    BOOLEAN     NOT NULL DEFAULT FALSE,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    run_id        UUID,
    batch_id      UUID
);

CREATE INDEX IF NOT EXISTS idx_tbl_work_item_claim_id  ON claims.tbl_work_item (claim_id);
CREATE INDEX IF NOT EXISTS idx_tbl_work_item_run_id    ON claims.tbl_work_item (run_id);
CREATE INDEX IF NOT EXISTS idx_tbl_work_item_batch_id  ON claims.tbl_work_item (batch_id);
CREATE INDEX IF NOT EXISTS idx_tbl_work_item_updated   ON claims.tbl_work_item (updated_at);

-- Full replica identity required for CDC UPDATE/DELETE capture
ALTER TABLE claims.tbl_work_item REPLICA IDENTITY FULL;
