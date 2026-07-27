WITH sales_summary AS (
  SELECT
    w.w_warehouse_name AS warehouse_name,
    sm.sm_type AS ship_mode_type,
    SUM(cs.cs_net_profit) AS amount,
    CAST('sales' AS varchar) AS record_type
  FROM catalog_sales cs
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  WHERE cs.cs_sold_date_sk = 2450836
  GROUP BY w.w_warehouse_name, sm.sm_type
),
returns_summary AS (
  SELECT
    w.w_warehouse_name AS warehouse_name,
    sm.sm_type AS ship_mode_type,
    SUM(cr.cr_net_loss) AS amount,
    CAST('return' AS varchar) AS record_type
  FROM catalog_returns cr
  JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
  JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
  WHERE cr.cr_returned_date_sk = 2450836
  GROUP BY w.w_warehouse_name, sm.sm_type
)
SELECT *
FROM (
  SELECT * FROM sales_summary
  UNION ALL
  SELECT * FROM returns_summary
) combined
ORDER BY amount DESC, warehouse_name ASC, ship_mode_type ASC
LIMIT 100
