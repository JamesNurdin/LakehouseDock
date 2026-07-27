WITH item_return_agg AS (
    SELECT
        sr.sr_item_sk,
        sr.sr_store_sk,
        SUM(sr.sr_return_amt) AS total_return_amt,
        COUNT(*) AS return_cnt,
        AVG(sr.sr_return_amt) AS avg_return_amt
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001
      AND REGEXP_LIKE(r.r_reason_desc, '(?i)damage')
    GROUP BY sr.sr_item_sk, sr.sr_store_sk
)
SELECT
    i.i_product_name,
    s.s_store_name,
    CONCAT(s.s_city, ', ', s.s_state) AS store_location,
    ira.total_return_amt,
    ira.return_cnt,
    REGEXP_EXTRACT(i.i_product_name, '(\\w+)-\\w+', 1) AS product_prefix,
    r.r_reason_desc
FROM item_return_agg ira
JOIN item i ON ira.sr_item_sk = i.i_item_sk
JOIN store s ON ira.sr_store_sk = s.s_store_sk
JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk AND sr.sr_store_sk = s.s_store_sk
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
WHERE i.i_product_name LIKE '%BLACK%'
  AND EXISTS (
        SELECT 1
        FROM store_returns sr2
        WHERE sr2.sr_item_sk = i.i_item_sk
          AND sr2.sr_return_amt > ira.avg_return_amt
    )
GROUP BY i.i_product_name,
         s.s_store_name,
         s.s_city,
         s.s_state,
         ira.total_return_amt,
         ira.return_cnt,
         REGEXP_EXTRACT(i.i_product_name, '(\\w+)-\\w+', 1),
         r.r_reason_desc
ORDER BY ira.total_return_amt DESC
LIMIT 100
