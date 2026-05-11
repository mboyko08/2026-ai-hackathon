-- ============================================================
-- Task 01 — PostgreSQL OLTP Schema: claims.tbl_claim
-- Database: db-oltp-pfl-1
-- ============================================================

CREATE TABLE IF NOT EXISTS claims.tbl_claim (
    claim_id      BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    claimant_id   BIGINT      NOT NULL REFERENCES claims.tbl_claimant (claimant_id),
    claim_number  TEXT        NOT NULL UNIQUE,
    claim_type    TEXT        NOT NULL,
    status        TEXT        NOT NULL DEFAULT 'open',
    amount        NUMERIC(14,2),
    is_deleted    BOOLEAN     NOT NULL DEFAULT FALSE,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    run_id        UUID,
    batch_id      UUID
);

CREATE INDEX IF NOT EXISTS idx_tbl_claim_claimant_id ON claims.tbl_claim (claimant_id);
CREATE INDEX IF NOT EXISTS idx_tbl_claim_run_id      ON claims.tbl_claim (run_id);
CREATE INDEX IF NOT EXISTS idx_tbl_claim_batch_id    ON claims.tbl_claim (batch_id);
CREATE INDEX IF NOT EXISTS idx_tbl_claim_updated     ON claims.tbl_claim (updated_at);

-- Full replica identity required for CDC UPDATE/DELETE capture
ALTER TABLE claims.tbl_claim REPLICA IDENTITY FULL;
