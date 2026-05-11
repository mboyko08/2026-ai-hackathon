-- ============================================================
-- Stored procedure: claims.insert_records
-- Inserts 10 new rows into each claims table per call.
--   tbl_claimant  → 10 new claimants
--   tbl_claim     → 10 new claims (reference the new claimants)
--   tbl_work_item → 10 new work items (reference the new claims)
-- All rows share the same run_id and batch_id for traceability.
-- ============================================================

CREATE OR REPLACE PROCEDURE claims.insert_records()
LANGUAGE plpgsql
AS $$
DECLARE
    v_run_id    UUID := gen_random_uuid();
    v_batch_id  UUID := gen_random_uuid();
    v_started   TIMESTAMPTZ := NOW();

    v_first_names  TEXT[] := ARRAY['Alice','Bob','Carol','David','Eve',
                                   'Frank','Grace','Hank','Iris','Jack'];
    v_last_names   TEXT[] := ARRAY['Johnson','Smith','White','Brown','Davis',
                                   'Miller','Wilson','Moore','Taylor','Anderson'];
    v_domains      TEXT[] := ARRAY['example.com','mail.com','inbox.com',
                                   'webmail.org','test.io'];
    v_claim_types  TEXT[] := ARRAY['medical','auto','property','liability','life'];
    v_priorities   TEXT[] := ARRAY['low','normal','high','urgent'];

    v_claimant_ids BIGINT[];
    v_claim_ids    BIGINT[];
    i              INTEGER;
    v_cid          BIGINT;
    v_claim_id     BIGINT;
BEGIN
    -- --------------------------------------------------------
    -- INSERT 10 claimants
    -- --------------------------------------------------------
    FOR i IN 1..10 LOOP
        INSERT INTO claims.tbl_claimant (
            first_name, last_name, email, phone,
            date_of_birth, status,
            created_at, updated_at,
            run_id, batch_id
        ) VALUES (
            v_first_names[i],
            v_last_names[i],
            lower(v_first_names[i]) || '.' || lower(v_last_names[i])
                || '_' || floor(random()*9000+1000)::INT
                || '@' || v_domains[1 + (i % array_length(v_domains,1))],
            '+1-555-' || lpad((floor(random()*9000+1000)::INT)::TEXT, 4, '0'),
            (NOW() - (365 * (20 + floor(random()*40)::INT) || ' days')::INTERVAL)::DATE,
            'active',
            NOW(), NOW(),
            v_run_id, v_batch_id
        )
        RETURNING claimant_id INTO v_cid;
        v_claimant_ids := array_append(v_claimant_ids, v_cid);
    END LOOP;

    -- --------------------------------------------------------
    -- INSERT 10 claims (one per new claimant)
    -- --------------------------------------------------------
    FOR i IN 1..10 LOOP
        INSERT INTO claims.tbl_claim (
            claimant_id, claim_number, claim_type,
            status, amount,
            created_at, updated_at,
            run_id, batch_id
        ) VALUES (
            v_claimant_ids[i],
            'CLM-' || to_char(NOW(),'YYYYMMDD') || '-' || lpad((floor(random()*90000+10000)::INT)::TEXT,5,'0'),
            v_claim_types[1 + (i % array_length(v_claim_types,1))],
            'open',
            round((random() * 50000 + 500)::NUMERIC, 2),
            NOW(), NOW(),
            v_run_id, v_batch_id
        )
        RETURNING claim_id INTO v_claim_id;
        v_claim_ids := array_append(v_claim_ids, v_claim_id);
    END LOOP;

    -- --------------------------------------------------------
    -- INSERT 10 work items (one per new claim)
    -- --------------------------------------------------------
    FOR i IN 1..10 LOOP
        INSERT INTO claims.tbl_work_item (
            claim_id, assigned_to, priority,
            status, description, due_date,
            created_at, updated_at,
            run_id, batch_id
        ) VALUES (
            v_claim_ids[i],
            'agent_' || lpad((floor(random()*20+1)::INT)::TEXT,2,'0'),
            v_priorities[1 + (i % array_length(v_priorities,1))],
            'pending',
            'Initial review for claim ' || v_claim_ids[i],
            (NOW() + ((7 + floor(random()*23)::INT) || ' days')::INTERVAL)::DATE,
            NOW(), NOW(),
            v_run_id, v_batch_id
        );
    END LOOP;

    RAISE NOTICE 'insert_records complete — run_id: %, batch_id: %, started: %',
        v_run_id, v_batch_id, v_started;
END;
$$;
