WITH sr_agg AS (
    SELECT
        sr_store_sk,
        SUM(sr_return_amt) AS total_return_amount,
        AVG(sr_return_tax) AS avg_return_tax,
        COUNT(*) AS return_cnt
    FROM store_returns
    WHERE sr_return_quantity > 1
    GROUP BY sr_store_sk
    HAVING SUM(sr_return_amt) > 1000
)
SELECT
    cc.cc_state,
    cc.cc_city,
    wh.w_warehouse_name,
    sr_agg.total_return_amount,
    sr_agg.avg_return_tax,
    sr_agg.return_cnt
FROM call_center cc
JOIN warehouse wh
    ON cc.cc_state = wh.w_state
   AND cc.cc_country = wh.w_country
JOIN sr_agg
    ON sr_agg.sr_store_sk = wh.w_warehouse_sk
WHERE cc.cc_gmt_offset BETWEEN -8.00 AND -5.00
  AND cc.cc_manager IN ('Bob Belcher', 'Mark Hightower')
ORDER BY sr_agg.total_return_amount DESC
LIMIT 100
