-- ============================================================
-- Task 01 — PostgreSQL OLTP Schema: claims.tbl_claimant
-- Database: db-oltp-pfl-1
-- ============================================================

CREATE TABLE IF NOT EXISTS claims.tbl_claimant (
    claimant_id   BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    first_name    TEXT        NOT NULL,
    last_name     TEXT        NOT NULL,
    email         TEXT        NOT NULL,
    phone         TEXT,
    date_of_birth DATE,
    status        TEXT        NOT NULL DEFAULT 'active',
    is_deleted    BOOLEAN     NOT NULL DEFAULT FALSE,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    run_id        UUID,
    batch_id      UUID
);

CREATE INDEX IF NOT EXISTS idx_tbl_claimant_run_id   ON claims.tbl_claimant (run_id);
CREATE INDEX IF NOT EXISTS idx_tbl_claimant_batch_id ON claims.tbl_claimant (batch_id);
CREATE INDEX IF NOT EXISTS idx_tbl_claimant_updated  ON claims.tbl_claimant (updated_at);

-- Full replica identity required for CDC UPDATE/DELETE capture
ALTER TABLE claims.tbl_claimant REPLICA IDENTITY FULL;
