WITH
  returns_agg AS (
    SELECT
      w.w_warehouse_id,
      sm.sm_ship_mode_id,
      SUM(cr.cr_return_amount) AS total_return_amount,
      COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE cr.cr_return_amount > 1000
    GROUP BY w.w_warehouse_id, sm.sm_ship_mode_id
  ),
  sales_agg AS (
    SELECT
      w.w_warehouse_id,
      sm.sm_ship_mode_id,
      SUM(ws.ws_ext_sales_price) AS total_sales_amount,
      COUNT(*) AS sales_cnt
    FROM web_sales ws
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE ws.ws_ext_sales_price > 2000
    GROUP BY w.w_warehouse_id, sm.sm_ship_mode_id
  )
SELECT
  'Return' AS metric_type,
  r.w_warehouse_id,
  r.sm_ship_mode_id,
  r.total_return_amount AS amount,
  r.return_cnt AS cnt
FROM returns_agg r
WHERE r.total_return_amount > (
  SELECT AVG(total_return_amount) FROM returns_agg
)
UNION ALL
SELECT
  'Sale' AS metric_type,
  s.w_warehouse_id,
  s.sm_ship_mode_id,
  s.total_sales_amount AS amount,
  s.sales_cnt AS cnt
FROM sales_agg s
WHERE s.total_sales_amount > (
  SELECT AVG(total_sales_amount) FROM sales_agg
)
ORDER BY amount DESC
