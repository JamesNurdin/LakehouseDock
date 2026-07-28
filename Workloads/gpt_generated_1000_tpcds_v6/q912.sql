WITH distinct_customers AS (
    SELECT DISTINCT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    WHERE regexp_like(c.c_email_address, '^.*@example\\.com$')
),
item_returns AS (
    SELECT
        sr.sr_customer_sk,
        i.i_item_id,
        i.i_item_desc,
        s.s_store_name,
        sr.sr_return_amt,
        sr.sr_return_quantity,
        CASE WHEN sr.sr_return_amt > 100 THEN 'High' ELSE 'Low' END AS return_level,
        (
            SELECT avg(sr2.sr_return_amt)
            FROM store_returns sr2
            WHERE sr2.sr_item_sk = i.i_item_sk
        ) AS avg_item_return_amt
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE regexp_like(i.i_item_desc, '(?i)TV|Phone')
      AND s.s_store_name LIKE '%Store%'
      AND substring(s.s_store_name, 1, 5) = 'Store'
)
SELECT
    dc.c_customer_id,
    dc.c_first_name || ' ' || dc.c_last_name AS full_name,
    ir.i_item_id,
    regexp_extract(ir.i_item_desc, '(?i)(TV|Phone)', 1) AS extracted_category,
    ir.s_store_name,
    ir.return_level,
    ir.sr_return_amt,
    ir.avg_item_return_amt,
    CASE WHEN ir.sr_return_amt > ir.avg_item_return_amt THEN 1 ELSE 0 END AS above_avg_flag
FROM distinct_customers dc
JOIN item_returns ir ON dc.c_customer_sk = ir.sr_customer_sk
ORDER BY ir.sr_return_amt DESC
LIMIT 100
