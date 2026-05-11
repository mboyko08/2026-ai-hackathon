-- ============================================================
-- Task 01 — PostgreSQL OLTP Schema
-- Database: db-oltp-pfl-1
-- ============================================================

-- ------------------------------------------------------------
-- Source data table
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS customers (
    customer_id   BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    full_name     TEXT        NOT NULL,
    email         TEXT        NOT NULL,
    phone         TEXT,
    status        TEXT        NOT NULL DEFAULT 'active',
    is_deleted    BOOLEAN     NOT NULL DEFAULT FALSE,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    run_id        UUID,
    batch_id      UUID
);

-- Index to speed up CDC queries that filter by run_id / batch_id
CREATE INDEX IF NOT EXISTS idx_customers_run_id   ON customers (run_id);
CREATE INDEX IF NOT EXISTS idx_customers_batch_id ON customers (batch_id);
CREATE INDEX IF NOT EXISTS idx_customers_updated  ON customers (updated_at);

-- ------------------------------------------------------------
-- Procedure execution log
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS pg_proc_log (
    log_id        BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    run_id        UUID        NOT NULL,
    batch_id      UUID        NOT NULL,
    procedure     TEXT        NOT NULL,
    started_at    TIMESTAMPTZ NOT NULL,
    ended_at      TIMESTAMPTZ,
    rows_inserted INTEGER     NOT NULL DEFAULT 0,
    rows_updated  INTEGER     NOT NULL DEFAULT 0,
    rows_deleted  INTEGER     NOT NULL DEFAULT 0,
    status        TEXT        NOT NULL DEFAULT 'running',
    error_message TEXT
);

CREATE INDEX IF NOT EXISTS idx_pg_proc_log_run_id ON pg_proc_log (run_id);

-- ------------------------------------------------------------
-- Stored procedure: generate_oltp_records
--
-- Behaviour per call:
--   INSERT 10 new customers
--   UPDATE 3 existing customers (oldest non-deleted rows)
--   Soft-DELETE 1 existing customer (oldest non-deleted, not yet deleted)
--
-- Every call gets a unique run_id (UUID) and batch_id (UUID).
-- One row is written to pg_proc_log at the end of each run.
-- ------------------------------------------------------------
CREATE OR REPLACE PROCEDURE generate_oltp_records()
LANGUAGE plpgsql
AS $$
DECLARE
    v_run_id        UUID := gen_random_uuid();
    v_batch_id      UUID := gen_random_uuid();
    v_started_at    TIMESTAMPTZ := NOW();
    v_rows_inserted INTEGER := 0;
    v_rows_updated  INTEGER := 0;
    v_rows_deleted  INTEGER := 0;
    v_names         TEXT[] := ARRAY[
        'Alice Johnson','Bob Smith','Carol White','David Brown','Eve Davis',
        'Frank Miller','Grace Wilson','Hank Moore','Iris Taylor','Jack Anderson'
    ];
    v_domains       TEXT[] := ARRAY[
        'example.com','mail.com','inbox.com','webmail.org','test.io'
    ];
    i               INTEGER;
    v_name          TEXT;
    v_email         TEXT;
    v_suffix        TEXT;
BEGIN
    -- --------------------------------------------------------
    -- INSERT 10 new customers
    -- --------------------------------------------------------
    FOR i IN 1..10 LOOP
        v_name   := v_names[i] || ' ' || LEFT(v_run_id::TEXT, 8);
        v_suffix := LOWER(REPLACE(v_names[i], ' ', '.'));
        v_email  := v_suffix || '+' || LEFT(v_run_id::TEXT, 6)
                    || '@' || v_domains[((i - 1) % array_length(v_domains, 1)) + 1];

        INSERT INTO customers (full_name, email, phone, status, run_id, batch_id)
        VALUES (
            v_name,
            v_email,
            '+1-555-' || LPAD((1000 + i)::TEXT, 4, '0'),
            'active',
            v_run_id,
            v_batch_id
        );
        v_rows_inserted := v_rows_inserted + 1;
    END LOOP;

    -- --------------------------------------------------------
    -- UPDATE 3 existing non-deleted customers (oldest first)
    -- --------------------------------------------------------
    UPDATE customers
    SET    status     = 'verified',
           updated_at = NOW(),
           run_id     = v_run_id,
           batch_id   = v_batch_id
    WHERE  customer_id IN (
               SELECT customer_id
               FROM   customers
               WHERE  is_deleted = FALSE
               ORDER  BY created_at
               LIMIT  3
           );
    GET DIAGNOSTICS v_rows_updated = ROW_COUNT;

    -- --------------------------------------------------------
    -- SOFT-DELETE 1 existing non-deleted customer (oldest first)
    -- --------------------------------------------------------
    UPDATE customers
    SET    is_deleted  = TRUE,
           status      = 'deleted',
           updated_at  = NOW(),
           run_id      = v_run_id,
           batch_id    = v_batch_id
    WHERE  customer_id = (
               SELECT customer_id
               FROM   customers
               WHERE  is_deleted = FALSE
               ORDER  BY created_at
               LIMIT  1
           );
    GET DIAGNOSTICS v_rows_deleted = ROW_COUNT;

    -- --------------------------------------------------------
    -- Write execution log
    -- --------------------------------------------------------
    INSERT INTO pg_proc_log (
        run_id, batch_id, procedure,
        started_at, ended_at,
        rows_inserted, rows_updated, rows_deleted,
        status
    ) VALUES (
        v_run_id, v_batch_id, 'generate_oltp_records',
        v_started_at, NOW(),
        v_rows_inserted, v_rows_updated, v_rows_deleted,
        'success'
    );

EXCEPTION
    WHEN OTHERS THEN
        -- Log the failure before re-raising
        INSERT INTO pg_proc_log (
            run_id, batch_id, procedure,
            started_at, ended_at,
            rows_inserted, rows_updated, rows_deleted,
            status, error_message
        ) VALUES (
            v_run_id, v_batch_id, 'generate_oltp_records',
            v_started_at, NOW(),
            v_rows_inserted, v_rows_updated, v_rows_deleted,
            'error', SQLERRM
        );
        RAISE;
END;
$$;
