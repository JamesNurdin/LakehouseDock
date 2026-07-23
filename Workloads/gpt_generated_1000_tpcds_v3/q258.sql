WITH
  returns_agg AS (
    SELECT
      d_return.d_year AS year,
      cc.cc_name AS call_center_name,
      w.w_warehouse_name AS warehouse_name,
      SUM(cr.cr_return_amount) AS total_return_amount,
      SUM(cr.cr_return_tax) AS total_return_tax,
      COUNT(*) AS return_count,
      COUNT(DISTINCT r.r_reason_desc) AS distinct_reason_count
    FROM catalog_returns cr
    JOIN date_dim d_return ON cr.cr_returned_date_sk = d_return.d_date_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN inventory inv_cur ON inv_cur.inv_date_sk = d_return.d_date_sk
      AND inv_cur.inv_warehouse_sk = w.w_warehouse_sk
    JOIN date_dim d_closed ON cc.cc_closed_date_sk = d_closed.d_date_sk
    JOIN date_dim d_open ON cc.cc_open_date_sk = d_open.d_date_sk
    LEFT JOIN inventory inv_prev ON inv_prev.inv_date_sk = d_closed.d_date_sk
      AND inv_prev.inv_warehouse_sk = w.w_warehouse_sk
    WHERE d_return.d_year = 2001
      AND r.r_reason_id = 'AAAAAAAAPAAAAAAA'
    GROUP BY d_return.d_year, cc.cc_name, w.w_warehouse_name
  ),
  inventory_agg AS (
    SELECT
      d_inv.d_year AS year,
      w.w_warehouse_name AS warehouse_name,
      SUM(inv.inv_quantity_on_hand) AS total_quantity_on_hand
    FROM inventory inv
    JOIN date_dim d_inv ON inv.inv_date_sk = d_inv.d_date_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    GROUP BY d_inv.d_year, w.w_warehouse_name
  ),
  combined_metrics AS (
    SELECT
      year,
      warehouse_name,
      'return_amount' AS metric_type,
      total_return_amount AS metric_value
    FROM returns_agg
    UNION ALL
    SELECT
      year,
      warehouse_name,
      'quantity_on_hand' AS metric_type,
      total_quantity_on_hand AS metric_value
    FROM inventory_agg
  ),
  reasons_distinct AS (
    SELECT DISTINCT r.r_reason_desc
    FROM reason r
    WHERE EXISTS (
      SELECT 1
      FROM catalog_returns cr
      JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
      WHERE cr.cr_reason_sk = r.r_reason_sk
        AND d_ret.d_year = 2001
    )
  )
SELECT
  cm.year,
  cm.warehouse_name,
  cm.metric_type,
  cm.metric_value,
  (SELECT COUNT(*) FROM reasons_distinct) AS distinct_reason_total
FROM combined_metrics cm
WHERE cm.metric_value > 0
ORDER BY cm.year DESC, cm.warehouse_name, cm.metric_type
LIMIT 100
