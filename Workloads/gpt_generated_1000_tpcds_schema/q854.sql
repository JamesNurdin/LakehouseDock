WITH
    -- Aggregate store returns at the store‑reason‑address‑customer level
    agg AS (
        SELECT
            sr.sr_store_sk,
            sr.sr_reason_sk,
            sr.sr_addr_sk,
            sr.sr_cdemo_sk,
            SUM(sr.sr_return_amt) AS total_return_amt,
            COUNT(*) AS cnt_returns
        FROM tpcds.store_returns sr
        GROUP BY sr.sr_store_sk, sr.sr_reason_sk, sr.sr_addr_sk, sr.sr_cdemo_sk
    ),
    -- Join the aggregate to the dimension tables and apply several filters
    detail AS (
        SELECT
            s.s_store_id AS store_id,
            s.s_city,
            s.s_state,
            s.s_tax_percentage,
            r.r_reason_desc AS reason_desc,
            ca.ca_state,
            cd.cd_gender,
            cd.cd_dep_employed_count,
            a.total_return_amt,
            a.cnt_returns,
            a.total_return_amt / a.cnt_returns AS avg_return_amt
        FROM agg a
        JOIN tpcds.store s        ON a.sr_store_sk = s.s_store_sk
        JOIN tpcds.reason r       ON a.sr_reason_sk = r.r_reason_sk
        JOIN tpcds.customer_address ca ON a.sr_addr_sk = ca.ca_address_sk
        JOIN tpcds.customer_demographics cd ON a.sr_cdemo_sk = cd.cd_demo_sk
        WHERE
            s.s_tax_percentage > 0.04                -- predicate 1
            AND ca.ca_state = 'CA'                  -- predicate 2
            AND cd.cd_gender = 'M'                  -- predicate 3
            AND cd.cd_dep_employed_count >= 1       -- predicate 4
            AND r.r_reason_desc LIKE '%damaged%'   -- predicate 5 (can be relaxed later)
    ),
    -- Two alternative slices of the detail data
    set_a AS (
        SELECT store_id, reason_desc, total_return_amt
        FROM detail
        WHERE reason_desc LIKE '%damaged%'
    ),
    set_b AS (
        SELECT store_id, reason_desc, total_return_amt
        FROM detail
        WHERE reason_desc LIKE '%color%'
    ),
    -- Union of the two slices (deduplicated)
    union_set AS (
        SELECT * FROM set_a
        UNION
        SELECT * FROM set_b
    ),
    -- A set to be removed (stores in Seattle with any reason)
    except_set AS (
        SELECT store_id, reason_desc, total_return_amt
        FROM detail
        WHERE s_city = 'Seattle'
    ),
    -- A second independent set for INTERSECT (high‑value returns)
    intersect_set AS (
        SELECT store_id, reason_desc, total_return_amt
        FROM detail
        WHERE total_return_amt > 1000
    ),
    -- Combine the set operations: (union ∩ intersect) – except
    final_pre AS (
        SELECT *
        FROM (
            SELECT * FROM union_set
            INTERSECT
            SELECT * FROM intersect_set
        )
        EXCEPT
        SELECT * FROM except_set
    )
SELECT
    fp.store_id,
    fp.reason_desc,
    fp.total_return_amt,
    LAG(fp.total_return_amt) OVER (PARTITION BY fp.store_id ORDER BY fp.total_return_amt DESC) AS prev_return_amt
FROM final_pre fp
ORDER BY fp.total_return_amt DESC
LIMIT 100
