-- ============================================================
-- Task 01 — PostgreSQL CDC: publication for claims schema
-- Database: db-oltp-pfl-1
--
-- Prerequisites:
--   wal_level = logical  (set via az postgres flexible-server parameter set
--                         + server restart)
--   Tables must exist before this file is applied.
--
-- Note: replication slots are created by the downstream connector
--       (e.g. Debezium) at connect time — not created here because
--       slot creation requires the REPLICATION role attribute.
-- ============================================================

-- Publication covering all three claims tables
DROP PUBLICATION IF EXISTS pub_claims_cdc;
CREATE PUBLICATION pub_claims_cdc
    FOR TABLE claims.tbl_claimant, claims.tbl_claim, claims.tbl_work_item
    WITH (publish = 'insert, update, delete');
