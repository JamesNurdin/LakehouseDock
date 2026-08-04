WITH cr_agg AS (
    SELECT
        cr_call_center_sk,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cr_return_quantity) AS total_return_qty,
        AVG(cr_return_tax) AS avg_return_tax,
        COUNT(*) AS return_cnt
    FROM catalog_returns
    WHERE cr_return_amount > 0
      AND cr_return_quantity > 0
      AND cr_return_ship_cost < 2000
      AND cr_store_credit BETWEEN 0 AND 500
      AND cr_fee < 100
      AND cr_returning_cdemo_sk IN (1725476, 1740425, 1915140)
    GROUP BY cr_call_center_sk
),
small_dim AS (
    SELECT 1 AS dim_key UNION ALL SELECT 2 UNION ALL SELECT 3
),
rank_params AS (
    SELECT seq AS rank_threshold FROM (VALUES (1), (2), (3), (4), (5)) AS t(seq)
)
SELECT
    cc.cc_call_center_id,
    cc.cc_name,
    cc.cc_state,
    cr_agg.total_return_amount,
    cr_agg.total_return_qty,
    cr_agg.return_cnt,
    ROW_NUMBER() OVER (PARTITION BY cc.cc_state ORDER BY cr_agg.total_return_amount DESC) AS state_rank,
    CASE
        WHEN cr_agg.total_return_amount > 10000 THEN 'HIGH'
        WHEN cr_agg.total_return_amount > 5000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS amount_category,
    dim.dim_key,
    rp.rank_threshold
FROM call_center cc
FULL OUTER JOIN cr_agg
    ON cc.cc_call_center_sk = cr_agg.cr_call_center_sk
CROSS JOIN small_dim dim
CROSS JOIN rank_params rp
WHERE cc.cc_rec_start_date BETWEEN DATE '1998-01-01' AND DATE '2002-12-31'
  AND cc.cc_gmt_offset BETWEEN -5.00 AND 5.00
  AND cc.cc_market_manager IS NOT NULL
  AND cc.cc_employees > 10
  AND cc.cc_sq_ft > 5000
  AND cc.cc_mkt_desc LIKE '%group%'
  AND EXISTS (
        SELECT 1 FROM catalog_returns cr2
        WHERE cr2.cr_call_center_sk = cc.cc_call_center_sk
          AND cr2.cr_return_amount > 2000
    )
ORDER BY cc.cc_state, state_rank
LIMIT 100
