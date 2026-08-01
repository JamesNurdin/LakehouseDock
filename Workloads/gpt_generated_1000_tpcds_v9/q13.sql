WITH aggregated_returns AS (
    SELECT
        cr.cr_call_center_sk,
        cr.cr_warehouse_sk,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 100
      AND cr.cr_ship_mode_sk IN (1, 2)
    GROUP BY cr.cr_call_center_sk, cr.cr_warehouse_sk
)
SELECT
    cc.cc_call_center_id,
    cc.cc_manager,
    cc.cc_state,
    cc.cc_city,
    wh.w_warehouse_id,
    wh.w_city,
    wh.w_state,
    ar.total_return_amount,
    ar.return_cnt,
    (SELECT MAX(cr2.cr_return_amount)
     FROM catalog_returns cr2
     WHERE cr2.cr_call_center_sk = cc.cc_call_center_sk
       AND cr2.cr_warehouse_sk = wh.w_warehouse_sk) AS max_return_amount,
    (SELECT AVG(cr3.cr_return_amount)
     FROM catalog_returns cr3
     WHERE cr3.cr_call_center_sk = cc.cc_call_center_sk
       AND cr3.cr_warehouse_sk = wh.w_warehouse_sk) AS avg_return_amount,
    lt.high_return_cnt,
    RANK() OVER (PARTITION BY wh.w_warehouse_id ORDER BY ar.total_return_amount DESC) AS warehouse_return_rank
FROM aggregated_returns ar
JOIN call_center cc
    ON ar.cr_call_center_sk = cc.cc_call_center_sk
JOIN warehouse wh
    ON ar.cr_warehouse_sk = wh.w_warehouse_sk
CROSS JOIN LATERAL (
    SELECT COUNT(*) AS high_return_cnt
    FROM catalog_returns cr_l
    WHERE cr_l.cr_call_center_sk = cc.cc_call_center_sk
      AND cr_l.cr_return_amount > 5000
) AS lt
WHERE cc.cc_manager IN ('Jason Brito', 'Wayne Ray')
  AND cc.cc_state = 'WA'
  AND wh.w_gmt_offset = -6.00
  AND NOT EXISTS (
      SELECT 1
      FROM catalog_returns cr_ex
      WHERE cr_ex.cr_call_center_sk = cc.cc_call_center_sk
        AND cr_ex.cr_return_amount > 10000
  )
ORDER BY ar.total_return_amount DESC, warehouse_return_rank ASC
LIMIT 100
