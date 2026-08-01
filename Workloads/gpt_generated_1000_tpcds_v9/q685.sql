SELECT
  i.i_category AS category,
  'sales' AS metric_type,
  SUM(cs.cs_quantity) AS total_quantity,
  SUM(cs.cs_net_paid_inc_ship) AS total_net_paid,
  CASE WHEN SUM(cs.cs_net_paid_inc_ship) > 10000 THEN 'High' ELSE 'Low' END AS revenue_bracket
FROM catalog_sales cs
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
WHERE cs.cs_sold_date_sk BETWEEN 2450800 AND 2450900
  AND i.i_brand_id IN (
    SELECT DISTINCT i2.i_brand_id
    FROM item i2
    WHERE i2.i_category = 'fragrances'
  )
GROUP BY i.i_category

UNION ALL

SELECT
  i.i_category AS category,
  'returns' AS metric_type,
  SUM(cr.cr_return_quantity) AS total_quantity,
  SUM(cr.cr_return_amount) AS total_net_paid,
  CASE WHEN SUM(cr.cr_return_amount) > 5000 THEN 'High' ELSE 'Low' END AS revenue_bracket
FROM catalog_returns cr
JOIN item i ON cr.cr_item_sk = i.i_item_sk
JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
WHERE cr.cr_returned_date_sk BETWEEN 2450800 AND 2450900
  AND EXISTS (
    SELECT 1
    FROM warehouse w2
    WHERE w2.w_warehouse_sk = cr.cr_warehouse_sk
      AND w2.w_state = 'CA'
  )
GROUP BY i.i_category
ORDER BY category, metric_type
LIMIT 100
