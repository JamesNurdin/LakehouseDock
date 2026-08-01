WITH return_data AS (
    SELECT DISTINCT
        'Return' AS entity_type,
        sr.sr_store_sk AS key_id,
        d.d_date_sk AS date_key,
        r.r_reason_desc AS description,
        sr.sr_return_amt AS amount,
        CASE WHEN sr.sr_return_amt > 100 THEN 'High' ELSE 'Low' END AS category,
        (SELECT SUM(sr2.sr_return_amt)
         FROM store_returns sr2
         WHERE sr2.sr_store_sk = sr.sr_store_sk) AS total_store_returns,
        ROW_NUMBER() OVER (PARTITION BY r.r_reason_desc ORDER BY sr.sr_return_amt DESC) AS rn,
        1 AS distinct_flag
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
      AND sr.sr_return_amt IS NOT NULL
),
promo_data AS (
    SELECT DISTINCT
        'Promotion' AS entity_type,
        c.cc_call_center_sk AS key_id,
        d.d_date_sk AS date_key,
        p.p_promo_name AS description,
        p.p_cost AS amount,
        CASE WHEN p.p_cost > 100 THEN 'High' ELSE 'Low' END AS category,
        (SELECT SUM(p2.p_cost)
         FROM promotion p2
         WHERE p2.p_promo_id = p.p_promo_id) AS total_store_returns,
        ROW_NUMBER() OVER (PARTITION BY p.p_promo_name ORDER BY p.p_cost DESC) AS rn,
        1 AS distinct_flag
    FROM promotion p
    JOIN date_dim d ON p.p_start_date_sk = d.d_date_sk
    JOIN call_center c ON c.cc_closed_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
      AND p.p_cost IS NOT NULL
)
SELECT *
FROM return_data
UNION ALL
SELECT *
FROM promo_data
ORDER BY entity_type, amount DESC, rn
LIMIT 100
