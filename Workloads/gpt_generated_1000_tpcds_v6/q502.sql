WITH sr_distinct AS (
    SELECT DISTINCT
        sr_store_sk,
        sr_reason_sk,
        sr_return_amt_inc_tax,
        sr_return_tax,
        sr_return_quantity
    FROM store_returns
    WHERE sr_store_sk IN (896, 547, 265, 139)                              -- predicate 1
      AND sr_return_amt_inc_tax > 20.00                                    -- predicate 2
      AND sr_return_tax BETWEEN 5 AND 30                                   -- predicate 3
      AND sr_return_quantity >= 1                                          -- predicate 4
)
SELECT
    sr_distinct.sr_store_sk,
    reason.r_reason_desc,
    SUM(sr_distinct.sr_return_amt_inc_tax) AS total_return_amt_inc_tax,
    COUNT(*) AS return_cnt,
    AVG(sr_distinct.sr_return_tax) AS avg_return_tax,
    CASE WHEN SUM(sr_distinct.sr_return_amt_inc_tax) > 200 THEN 'High' ELSE 'Low' END AS risk_level,
    RANK() OVER (PARTITION BY reason.r_reason_desc ORDER BY SUM(sr_distinct.sr_return_amt_inc_tax) DESC) AS reason_store_rank
FROM sr_distinct
LEFT JOIN reason
    ON sr_distinct.sr_reason_sk = reason.r_reason_sk
   AND reason.r_reason_id LIKE 'AAAAAAA%'
GROUP BY
    sr_distinct.sr_store_sk,
    reason.r_reason_desc
HAVING SUM(sr_distinct.sr_return_amt_inc_tax) > 100
ORDER BY total_return_amt_inc_tax DESC
LIMIT 50
