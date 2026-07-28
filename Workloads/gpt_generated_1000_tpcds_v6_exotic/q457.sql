WITH avg_return AS (
       SELECT avg(cr_return_amount) AS avg_amt
       FROM catalog_returns
     )
SELECT
  cp.cp_catalog_page_id,
  sm.sm_ship_mode_id,
  w.w_warehouse_id,
  SUM(cr.cr_return_amount) AS total_return_amount,
  COUNT(*) AS return_cnt,
  SUM(cr.cr_return_amount) / (SELECT avg_amt FROM avg_return) AS return_amount_factor
FROM catalog_returns cr
JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
WHERE sm.sm_carrier = 'FEDEX'
  AND w.w_state = 'CA'
GROUP BY cp.cp_catalog_page_id, sm.sm_ship_mode_id, w.w_warehouse_id

UNION ALL

SELECT
  cp.cp_catalog_page_id,
  sm.sm_ship_mode_id,
  w.w_warehouse_id,
  SUM(cr.cr_return_amount) AS total_return_amount,
  COUNT(*) AS return_cnt,
  SUM(cr.cr_return_amount) / (SELECT avg_amt FROM avg_return) AS return_amount_factor
FROM catalog_returns cr
JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
WHERE sm.sm_carrier = 'TBS'
  AND w.w_state = 'TX'
GROUP BY cp.cp_catalog_page_id, sm.sm_ship_mode_id, w.w_warehouse_id

ORDER BY total_return_amount DESC
LIMIT 100
