WITH sr_agg AS (
    SELECT
        sr_reason_sk,
        SUM(sr_return_amt) AS total_return_amt,
        AVG(sr_return_quantity) AS avg_return_qty,
        COUNT(*) AS cnt_returns,
        MIN(sr_return_ship_cost) AS min_ship_cost,
        MAX(sr_return_ship_cost) AS max_ship_cost
    FROM tpcds.store_returns
    TABLESAMPLE BERNOULLI (10)
    WHERE sr_return_ship_cost > 10.00
      AND sr_return_quantity BETWEEN 1 AND 5
      AND sr_item_sk IN (38281, 271991, 92064)
      AND sr_return_time_sk >= 30000
      AND sr_return_time_sk <= 60000
    GROUP BY sr_reason_sk
)
SELECT
    r.r_reason_id,
    r.r_reason_desc,
    sr_agg.total_return_amt,
    sr_agg.avg_return_qty,
    sr_agg.cnt_returns,
    sr_agg.min_ship_cost,
    sr_agg.max_ship_cost
FROM tpcds.reason r
JOIN sr_agg ON r.r_reason_sk = sr_agg.sr_reason_sk
WHERE r.r_reason_desc LIKE '%size%'
   OR r.r_reason_desc LIKE '%missing%'
   OR r.r_reason_id = 'AAAAAAAACBAAAAAA'
   OR r.r_reason_id = 'AAAAAAAABBAAAAAA'
   OR r.r_reason_id = 'AAAAAAAALAAAAAAA'
ORDER BY sr_agg.total_return_amt DESC
LIMIT 100
